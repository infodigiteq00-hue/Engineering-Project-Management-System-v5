import React, { useState, useEffect } from "react";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Calendar, Clock, Send, Download, TrendingUp, X } from "lucide-react";
import { fastAPI } from "@/lib/api";
import { useToast } from "@/hooks/use-toast";

interface RevisionEvent {
  id: string;
  event_type: 'submitted' | 'received';
  revision_number: string;
  event_date: string;
  estimated_return_date?: string;
  actual_return_date?: string;
  days_elapsed?: number;
  notes?: string;
  created_by_user?: {
    full_name?: string;
    email?: string;
  };
}

interface VDCRRevisionHistoryProps {
  vdcrRecordId: string;
  documentName: string;
  currentRevision?: string; // Current revision number from VDCR record
  projectId?: string; // Project ID to fetch latest revision
  isOpen: boolean;
  onClose: () => void;
}

const VDCRRevisionHistory: React.FC<VDCRRevisionHistoryProps> = ({
  vdcrRecordId,
  documentName,
  currentRevision,
  projectId,
  isOpen,
  onClose
}) => {
  const { toast } = useToast();
  const [events, setEvents] = useState<RevisionEvent[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [latestRevision, setLatestRevision] = useState<string | undefined>(currentRevision);

  useEffect(() => {
    if (isOpen && vdcrRecordId) {
      loadRevisionEvents();
      loadLatestRevision();
    }
  }, [isOpen, vdcrRecordId, currentRevision]);

  // Update latest revision when currentRevision prop changes
  useEffect(() => {
    if (currentRevision) {
      setLatestRevision(currentRevision);
    }
  }, [currentRevision]);

  const loadLatestRevision = async () => {
    try {
      // Fetch the latest VDCR record by project to get current revision
      if (projectId) {
        const response = await fastAPI.getVDCRRecordsByProject(projectId);
        // Search through all records to find the one we need
        const record = (response as any[]).find((r: any) => r.id === vdcrRecordId);
        if (record && record.revision) {
          setLatestRevision(record.revision);
          return;
        }
      }
      // Fallback to prop if fetch fails or no projectId
      if (currentRevision) {
        setLatestRevision(currentRevision);
      }
    } catch (error) {
      // Silently fail - use the prop value
      if (currentRevision) {
        setLatestRevision(currentRevision);
      }
    }
  };

  const loadRevisionEvents = async () => {
    try {
      setIsLoading(true);
      const data = await fastAPI.getVDCRRevisionEvents(vdcrRecordId);
      setEvents(data || []);
    } catch (error) {
      console.error('Error loading revision events:', error);
      toast({ title: 'Error', description: 'Failed to load revision history.', variant: 'destructive' });
    } finally {
      setIsLoading(false);
    }
  };

  const calculateDaysBetween = (startDate: string, endDate: string): number => {
    const start = new Date(startDate);
    const end = new Date(endDate);
    const diffTime = Math.abs(end.getTime() - start.getTime());
    return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  };

  const calculateStatistics = () => {
    if (events.length === 0) return null;

    let totalDaysWithClient = 0;
    let totalDaysWorked = 0;
    let submissionCount = 0;
    let receiptCount = 0;
    let pendingWithClient = false;
    let lastSubmissionDate: string | null = null;

    // Sort events by date
    const sortedEvents = [...events].sort((a, b) => 
      new Date(a.event_date).getTime() - new Date(b.event_date).getTime()
    );

    for (let i = 0; i < sortedEvents.length; i++) {
      const event = sortedEvents[i];
      
      if (event.event_type === 'submitted') {
        submissionCount++;
        lastSubmissionDate = event.event_date;
        pendingWithClient = true;
      } else if (event.event_type === 'received') {
        receiptCount++;
        if (lastSubmissionDate) {
          const days = calculateDaysBetween(lastSubmissionDate, event.event_date);
          totalDaysWithClient += days;
          pendingWithClient = false;
          lastSubmissionDate = null;
        }
      }

      // Calculate days worked (between receipt and next submission)
      if (i > 0 && sortedEvents[i - 1].event_type === 'received' && event.event_type === 'submitted') {
        const days = calculateDaysBetween(sortedEvents[i - 1].event_date, event.event_date);
        totalDaysWorked += days;
      }
    }

    // If still pending with client, calculate days from last submission to now
    if (pendingWithClient && lastSubmissionDate) {
      const days = calculateDaysBetween(lastSubmissionDate, new Date().toISOString());
      totalDaysWithClient += days;
    }

    return {
      totalDaysWithClient,
      totalDaysWorked,
      submissionCount,
      receiptCount,
      pendingWithClient,
      lastSubmissionDate
    };
  };

  const stats = calculateStatistics();

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  const formatDateShort = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    });
  };

  const formatDateOnly = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    });
  };

  const getDaysSinceSubmission = (submissionDate: string): number => {
    return calculateDaysBetween(submissionDate, new Date().toISOString());
  };

  // Get last event information
  const getLastEventInfo = () => {
    if (events.length === 0) return null;

    const sortedEvents = [...events].sort((a, b) => 
      new Date(b.event_date).getTime() - new Date(a.event_date).getTime()
    );
    
    const lastEvent = sortedEvents[0];
    const daysSince = calculateDaysBetween(lastEvent.event_date, new Date().toISOString());
    
    // Use latest revision (fetched fresh) if available, otherwise use prop, otherwise fall back to event's revision
    const displayRevision = latestRevision || currentRevision || lastEvent.revision_number;
    
    return {
      event: lastEvent,
      daysSince,
      eventTypeText: lastEvent.event_type === 'submitted' ? 'Submitted' : 'Received',
      date: formatDateShort(lastEvent.event_date),
      revision: displayRevision
    };
  };

  const lastEventInfo = getLastEventInfo();

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="text-2xl font-bold text-gray-800 flex items-center justify-between">
            <span>Revision History - {documentName}</span>
            <Button variant="ghost" size="sm" onClick={onClose}>
              <X className="w-4 h-4" />
            </Button>
          </DialogTitle>
        </DialogHeader>

        {isLoading ? (
          <div className="flex items-center justify-center py-12">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
          </div>
        ) : (
          <div className="space-y-6">
            {/* Last Event Highlight - Primary Display */}
            {lastEventInfo && (
              <div className="bg-gradient-to-r from-blue-50 via-indigo-50 to-purple-50 rounded-xl border-2 border-blue-200 shadow-lg overflow-hidden">
                <div className="p-5">
                  <div className="flex items-center justify-between gap-6">
                    {/* Left: Icon and Days */}
                    <div className="flex items-center gap-4">
                      <div className={`p-4 rounded-xl shadow-sm ${
                        lastEventInfo.event.event_type === 'submitted' 
                          ? 'bg-blue-100 border-2 border-blue-300' 
                          : 'bg-green-100 border-2 border-green-300'
                      }`}>
                        {lastEventInfo.event.event_type === 'submitted' ? (
                          <Send className="w-8 h-8 text-blue-700" />
                        ) : (
                          <Download className="w-8 h-8 text-green-700" />
                        )}
                      </div>
                      <div>
                        <div className="text-xs text-gray-500 uppercase tracking-wide mb-1">Last Event</div>
                        <div className="text-3xl font-bold text-gray-900">
                          {lastEventInfo.daysSince}
                        </div>
                        <div className="text-sm text-gray-600 font-medium">days ago</div>
                      </div>
                    </div>

                    {/* Middle: Event Type and Revision */}
                    <div className="flex-1 flex items-center gap-4">
                      <div className="h-12 w-px bg-gray-300"></div>
                      <div>
                        <div className="text-xs text-gray-500 uppercase tracking-wide mb-2">Event Type</div>
                        <div className="flex items-center gap-2">
                          <Badge className={`text-sm px-3 py-1 ${
                            lastEventInfo.event.event_type === 'submitted'
                              ? 'bg-blue-500 text-white border-blue-600'
                              : 'bg-green-500 text-white border-green-600'
                          }`}>
                            {lastEventInfo.eventTypeText}
                          </Badge>
                          {lastEventInfo.revision && (
                            <Badge variant="outline" className="font-mono text-sm px-3 py-1 bg-white">
                              Rev {lastEventInfo.revision}
                            </Badge>
                          )}
                        </div>
                      </div>
                    </div>

                    {/* Right: Date and User */}
                    <div className="flex items-center gap-4">
                      <div className="h-12 w-px bg-gray-300"></div>
                      <div className="text-right">
                        <div className="text-xs text-gray-500 uppercase tracking-wide mb-2">Date</div>
                        <div className="flex items-center gap-2 text-gray-800 font-semibold">
                          <Calendar className="w-4 h-4 text-gray-500" />
                          <span>{lastEventInfo.date}</span>
                        </div>
                        {lastEventInfo.event.created_by_user && (
                          <div className="text-xs text-gray-600 mt-1">
                            by {lastEventInfo.event.created_by_user.full_name || lastEventInfo.event.created_by_user.email || 'Unknown'}
                          </div>
                        )}
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* Statistics Summary */}
            {stats && (
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4 p-4 bg-gradient-to-br from-blue-50 to-indigo-50 rounded-lg border border-blue-200">
                <div className="text-center">
                  <div className="text-2xl font-bold text-blue-700">{stats.totalDaysWorked}</div>
                  <div className="text-xs text-gray-600 mt-1">Days Worked</div>
                </div>
                <div className="text-center">
                  <div className="text-2xl font-bold text-purple-700">{stats.totalDaysWithClient}</div>
                  <div className="text-xs text-gray-600 mt-1">Days with Client</div>
                </div>
                <div className="text-center">
                  <div className="text-2xl font-bold text-green-700">{stats.submissionCount}</div>
                  <div className="text-xs text-gray-600 mt-1">Submissions</div>
                </div>
                <div className="text-center">
                  <div className="text-2xl font-bold text-orange-700">{stats.receiptCount}</div>
                  <div className="text-xs text-gray-600 mt-1">Receipts</div>
                </div>
              </div>
            )}

            {/* Timeline */}
            <div className="space-y-4">
              <h3 className="text-lg font-semibold text-gray-800">Event Timeline</h3>
              {events.length === 0 ? (
                <div className="text-center py-8 text-gray-500">
                  <Clock className="w-12 h-12 mx-auto mb-2 text-gray-400" />
                  <p>No revision events recorded yet.</p>
                  <p className="text-sm mt-1">Start tracking by submitting or receiving documents.</p>
                </div>
              ) : (
                <div className="space-y-3">
                  {events.map((event, index) => {
                    const isSubmitted = event.event_type === 'submitted';
                    const nextEvent = events[index + 1];
                    const daysElapsed = event.days_elapsed || 
                      (nextEvent && nextEvent.event_type === 'received' 
                        ? calculateDaysBetween(event.event_date, nextEvent.event_date)
                        : isSubmitted && stats?.pendingWithClient
                        ? getDaysSinceSubmission(event.event_date)
                        : null);

                    // For received events, find the previous submission to get estimated return date and calculate days
                    let estimatedReturnInfo = null;
                    let daysSinceSubmission = null;
                    if (!isSubmitted) {
                      // Events are sorted by date descending (newest first), so look at later indices for earlier events
                      // Find the most recent submission before this received event (in chronological order)
                      for (let i = index + 1; i < events.length; i++) {
                        if (events[i].event_type === 'submitted') {
                          // Calculate days since submission
                          daysSinceSubmission = calculateDaysBetween(events[i].event_date, event.event_date);
                          
                          // If this submission has an estimated return date, calculate before/after
                          if (events[i].estimated_return_date) {
                            const estimatedDate = new Date(events[i].estimated_return_date);
                            const receivedDate = new Date(event.event_date);
                            // Calculate days difference (always positive)
                            const daysDiff = Math.abs(calculateDaysBetween(events[i].estimated_return_date, event.event_date));
                            // Check if received date is before or after estimated date
                            const isBefore = receivedDate.getTime() < estimatedDate.getTime();
                            estimatedReturnInfo = {
                              days: daysDiff,
                              isBefore: isBefore
                            };
                          }
                          break;
                        }
                      }
                    }

                    return (
                      <div key={event.id} className="flex gap-4">
                        {/* Timeline Line */}
                        <div className="flex flex-col items-center pt-1">
                          <div className={`w-2.5 h-2.5 rounded-full border-2 ${
                            isSubmitted 
                              ? 'bg-blue-500 border-blue-300' 
                              : 'bg-green-500 border-green-300'
                          }`}></div>
                          {index < events.length - 1 && (
                            <div className="w-0.5 h-full bg-gray-200 mt-1.5"></div>
                          )}
                        </div>

                        {/* Event Content - Horizontal Layout */}
                        <div className="flex-1 pb-3">
                          <div className={`p-4 rounded-lg border ${
                            isSubmitted 
                              ? 'bg-white border-blue-200/50 hover:border-blue-300' 
                              : 'bg-white border-green-200/50 hover:border-green-300'
                          } transition-all shadow-sm hover:shadow-md`}>
                            <div className="flex items-center justify-between gap-4">
                              {/* Left: Icon and Type */}
                              <div className="flex items-center gap-3 min-w-[180px]">
                                <div className={`p-2 rounded-lg ${
                                  isSubmitted 
                                    ? 'bg-blue-50 border border-blue-200' 
                                    : 'bg-green-50 border border-green-200'
                                }`}>
                                  {isSubmitted ? (
                                    <Send className="w-4 h-4 text-blue-600" />
                                  ) : (
                                    <Download className="w-4 h-4 text-green-600" />
                                  )}
                                </div>
                                <div>
                                  <Badge className={`text-xs px-2 py-0.5 ${
                                    isSubmitted 
                                      ? 'bg-blue-100 text-blue-700 border-blue-300' 
                                      : 'bg-green-100 text-green-700 border-green-300'
                                  }`}>
                                    {isSubmitted ? 'Submitted' : 'Received'}
                                  </Badge>
                                  <div className="mt-1">
                                    <Badge variant="outline" className="text-xs font-mono px-2 py-0.5 bg-gray-50">
                                      Rev {event.revision_number}
                                    </Badge>
                                  </div>
                                </div>
                              </div>

                              {/* Middle: Details */}
                              <div className="flex-1 space-y-1.5">
                                {isSubmitted && daysElapsed !== null && (
                                  <div className="flex items-center gap-2 text-sm">
                                    <TrendingUp className="w-3.5 h-3.5 text-gray-400" />
                                    <span className="text-gray-700 font-medium">
                                      {daysElapsed} days with client{stats?.pendingWithClient && index === 0 ? ' (ongoing)' : ''}
                                    </span>
                                  </div>
                                )}
                                {!isSubmitted && daysSinceSubmission !== null && (
                                  <div className="flex items-center gap-2 text-sm">
                                    <TrendingUp className="w-3.5 h-3.5 text-gray-400" />
                                    <span className="text-gray-700 font-medium">
                                      Received after {daysSinceSubmission} days since submission
                                    </span>
                                  </div>
                                )}
                                <div className="flex items-center gap-2 text-sm text-gray-600">
                                  <Calendar className="w-3.5 h-3.5 text-gray-400" />
                                  <span>
                                    {isSubmitted ? 'Sent on: ' : 'Received on: '}
                                    {formatDate(event.event_date)}
                                  </span>
                                </div>
                                {event.notes && (
                                  <div className="text-xs text-gray-600 italic">
                                    {event.notes}
                                  </div>
                                )}
                              </div>

                              {/* Right: Estimated Return Date (for submitted) or Before/After Estimated (for received) and User */}
                              <div className="text-right min-w-[140px]">
                                {isSubmitted && event.estimated_return_date && (
                                  <div className="text-xs font-semibold text-gray-700 mb-1">
                                    <span className="text-gray-500 font-normal">Est. return: </span>
                                    {formatDateOnly(event.estimated_return_date)}
                                  </div>
                                )}
                                {!isSubmitted && estimatedReturnInfo && (
                                  <div className={`text-xs font-semibold mb-1 ${
                                    estimatedReturnInfo.isBefore 
                                      ? 'text-green-600' 
                                      : 'text-red-600'
                                  }`}>
                                    {estimatedReturnInfo.days} days {estimatedReturnInfo.isBefore ? 'before' : 'after'} est. return
                                  </div>
                                )}
                                {event.created_by_user && (
                                  <div className="text-xs text-gray-500">
                                    {event.created_by_user.full_name || event.created_by_user.email || 'Unknown'}
                                  </div>
                                )}
                              </div>
                            </div>
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          </div>
        )}
      </DialogContent>
    </Dialog>
  );
};

export default VDCRRevisionHistory;

