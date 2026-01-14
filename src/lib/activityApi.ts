import axios from "axios";
import { supabase } from './supabase';

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL;
const SUPABASE_ANON_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY;

// Create axios instance for Supabase
const api = axios.create({
  baseURL: `${SUPABASE_URL}/rest/v1`,
  headers: {
    'apikey': SUPABASE_ANON_KEY,
    'Content-Type': 'application/json',
    'Prefer': 'return=representation'
  },
  timeout: 30000 // 30 seconds timeout
});

// Cache for session token to avoid repeated getSession() calls
let cachedSessionToken: string | null = null;
let sessionCacheTime = 0;
const SESSION_CACHE_DURATION = 5 * 60 * 1000; // 5 minutes

// Helper function to get session token with fallbacks
async function getSessionToken(): Promise<string | null> {
  // Try to get from cache first (if less than 5 minutes old)
  if (cachedSessionToken && Date.now() - sessionCacheTime < SESSION_CACHE_DURATION) {
    return cachedSessionToken;
  }
  
  // Try to get from localStorage (Supabase stores session there)
  try {
    const storageKey = 'sb-ypdlbqrcxnugrvllbmsi-auth-token';
    const storedSession = localStorage.getItem(storageKey);
    if (storedSession) {
      const parsed = JSON.parse(storedSession);
      if (parsed?.access_token) {
        cachedSessionToken = parsed.access_token;
        sessionCacheTime = Date.now();
        return cachedSessionToken;
      }
    }
  } catch (e) {
    // Ignore localStorage errors
  }
  
  // Fallback: Try getSession with short timeout
  try {
    const sessionPromise = supabase.auth.getSession();
    const timeoutPromise = new Promise((_, reject) => 
      setTimeout(() => reject(new Error('getSession timeout')), 2000) // 2 second timeout
    );
    
    const { data: { session }, error } = await Promise.race([sessionPromise, timeoutPromise]) as any;
    
    if (!error && session?.access_token) {
      cachedSessionToken = session.access_token;
      sessionCacheTime = Date.now();
      return cachedSessionToken;
    }
  } catch (error) {
    // Ignore getSession errors
  }
  
  return null;
}

// Add request interceptor to dynamically set Authorization header with user's JWT token
// This is required for RLS (Row Level Security) to work correctly
api.interceptors.request.use(async (config) => {
  try {
    const token = await getSessionToken();
    
    if (token) {
      // Use the user's JWT token for authenticated requests
      // This allows RLS policies to identify the user via auth.uid()
      config.headers.Authorization = `Bearer ${token}`;
    } else {
      // Fallback to anon key if no session (for public/unauthenticated requests)
      config.headers.Authorization = `Bearer ${SUPABASE_ANON_KEY}`;
    }
  } catch (error) {
    console.error('Error getting session for API request:', error);
    // Fallback to anon key on error to prevent breaking existing functionality
    config.headers.Authorization = `Bearer ${SUPABASE_ANON_KEY}`;
  }
  
  return config;
});

// Activity logging API functions
export const activityApi = {
  // Log equipment activity
  async logEquipmentActivity(data: {
    projectId: string | null; // Nullable to support standalone equipment
    equipmentId?: string;
    activityType: string;
    actionDescription: string;
    fieldName?: string;
    oldValue?: string;
    newValue?: string;
    metadata?: any;
    createdBy: string;
  }) {
    try {
      // console.log('📝 Logging equipment activity:', data);
      
      const logData = {
        project_id: data.projectId,
        equipment_id: data.equipmentId || null,
        activity_type: data.activityType,
        action_description: data.actionDescription,
        field_name: data.fieldName || null,
        old_value: data.oldValue || null,
        new_value: data.newValue || null,
        metadata: data.metadata || {},
        created_by: data.createdBy
      };

      const response = await api.post('/equipment_activity_logs', logData);
      // console.log('✅ Activity logged successfully:', response.data);
      return response.data;
    } catch (error) {
      console.error('❌ Error logging activity:', error);
      // Don't throw error to prevent breaking the main action
      return null;
    }
  },

  // Get equipment activity logs by project
  async getEquipmentActivityLogs(projectId: string, filters?: {
    equipmentId?: string;
    activityType?: string;
    userId?: string;
    dateFrom?: string;
    dateTo?: string;
    limit?: number;
    offset?: number;
  }) {
    try {
      // console.log('📋 Fetching equipment activity logs for project:', projectId);
      
      let query = `/equipment_activity_logs?project_id=eq.${projectId}`;
      
      // Add filters
      if (filters?.equipmentId) {
        query += `&equipment_id=eq.${filters.equipmentId}`;
      }
      if (filters?.activityType) {
        query += `&activity_type=eq.${filters.activityType}`;
      }
      if (filters?.userId) {
        query += `&created_by=eq.${filters.userId}`;
      }
      if (filters?.dateFrom) {
        query += `&created_at=gte.${filters.dateFrom}`;
      }
      if (filters?.dateTo) {
        query += `&created_at=lte.${filters.dateTo}`;
      }
      
      // Add ordering and pagination
      query += `&order=created_at.desc`;
      if (filters?.limit) {
        query += `&limit=${filters.limit}`;
      }
      if (filters?.offset) {
        query += `&offset=${filters.offset}`;
      }
      
      // Add user information and equipment data
      query += `&select=*,equipment:equipment_id(id,tag_number,type,name,project_id),created_by_user:created_by(full_name,email)`;
      
      // console.log('🔧 activityApi: Equipment logs query:', query);
      const response = await api.get(query);
      const logs = Array.isArray(response.data) ? response.data : [];
      // console.log('🔧 activityApi: Equipment logs fetched successfully:', {
      //   count: logs.length,
      //   firstLog: logs[0],
      //   allLogs: logs
      // });
      return logs;
    } catch (error: any) {
      console.error('❌ activityApi: Error fetching equipment activity logs:', error);
      console.error('❌ activityApi: Error response:', error?.response?.data);
      console.error('❌ activityApi: Error status:', error?.response?.status);
      return [];
    }
  },

  // Get activity logs for specific equipment
  async getEquipmentActivityLogsByEquipment(equipmentId: string, filters?: {
    activityType?: string;
    userId?: string;
    dateFrom?: string;
    dateTo?: string;
    limit?: number;
    offset?: number;
  }) {
    try {
      // console.log('📋 Fetching activity logs for equipment:', equipmentId);
      
      let query = `/equipment_activity_logs?equipment_id=eq.${equipmentId}`;
      
      // Add filters
      if (filters?.activityType) {
        query += `&activity_type=eq.${filters.activityType}`;
      }
      if (filters?.userId) {
        query += `&created_by=eq.${filters.userId}`;
      }
      if (filters?.dateFrom) {
        query += `&created_at=gte.${filters.dateFrom}`;
      }
      if (filters?.dateTo) {
        query += `&created_at=lte.${filters.dateTo}`;
      }
      
      // Add ordering and pagination
      query += `&order=created_at.desc`;
      if (filters?.limit) {
        query += `&limit=${filters.limit}`;
      }
      if (filters?.offset) {
        query += `&offset=${filters.offset}`;
      }
      
      // Add user information
      query += `&select=*,created_by_user:created_by(full_name,email)`;
      
      const response = await api.get(query);
      // console.log('✅ Equipment activity logs fetched successfully:', response.data);
      return response.data;
    } catch (error) {
      console.error('❌ Error fetching equipment activity logs:', error);
      throw error;
    }
  },

  // Get activity statistics
  async getActivityStatistics(projectId: string, dateFrom?: string, dateTo?: string) {
    try {
      // console.log('📊 Fetching activity statistics for project:', projectId);
      
      let query = `/equipment_activity_logs?project_id=eq.${projectId}`;
      
      if (dateFrom) {
        query += `&created_at=gte.${dateFrom}`;
      }
      if (dateTo) {
        query += `&created_at=lte.${dateTo}`;
      }
      
      query += `&select=activity_type,created_at,created_by`;
      
      const response = await api.get(query);
      const logs = Array.isArray(response.data) ? response.data : [];
      
      // Calculate statistics
      const stats = {
        totalActivities: logs.length,
        activitiesByType: logs.reduce((acc: any, log: any) => {
          acc[log.activity_type] = (acc[log.activity_type] || 0) + 1;
          return acc;
        }, {}),
        activitiesByUser: logs.reduce((acc: any, log: any) => {
          const userId = log.created_by;
          acc[userId] = (acc[userId] || 0) + 1;
          return acc;
        }, {}),
        recentActivities: logs.slice(0, 10)
      };
      
      // console.log('✅ Activity statistics calculated:', stats);
      return stats;
    } catch (error) {
      console.error('❌ Error fetching activity statistics:', error);
      throw error;
    }
  },

  // ============================================================================
  // STANDALONE EQUIPMENT ACTIVITY LOGS
  // ============================================================================

  // Log standalone equipment activity (separate table)
  async logStandaloneEquipmentActivity(data: {
    equipmentId: string;
    activityType: string;
    actionDescription: string;
    fieldName?: string;
    oldValue?: string;
    newValue?: string;
    metadata?: any;
    createdBy: string;
  }) {
    try {
      // console.log('📝 Logging standalone equipment activity:', data);
      
      const logData = {
        equipment_id: data.equipmentId,
        activity_type: data.activityType,
        action_description: data.actionDescription,
        field_name: data.fieldName || null,
        old_value: data.oldValue || null,
        new_value: data.newValue || null,
        metadata: data.metadata || {},
        created_by: data.createdBy
      };

      const response = await api.post('/standalone_equipment_activity_logs', logData);
      // console.log('✅ Standalone equipment activity logged successfully:', response.data);
      return response.data;
    } catch (error) {
      console.error('❌ Error logging standalone equipment activity:', error);
      // Don't throw error to prevent breaking the main action
      return null;
    }
  },

  // Get activity logs for specific standalone equipment
  async getStandaloneEquipmentActivityLogsByEquipment(equipmentId: string, filters?: {
    activityType?: string;
    userId?: string;
    dateFrom?: string;
    dateTo?: string;
    limit?: number;
    offset?: number;
  }) {
    try {
      // console.log('📋 Fetching activity logs for standalone equipment:', equipmentId);
      
      let query = `/standalone_equipment_activity_logs?equipment_id=eq.${equipmentId}`;
      
      // Add filters
      if (filters?.activityType) {
        query += `&activity_type=eq.${filters.activityType}`;
      }
      if (filters?.userId) {
        query += `&created_by=eq.${filters.userId}`;
      }
      if (filters?.dateFrom) {
        query += `&created_at=gte.${filters.dateFrom}`;
      }
      if (filters?.dateTo) {
        query += `&created_at=lte.${filters.dateTo}`;
      }
      
      // Add ordering and pagination
      query += `&order=created_at.desc`;
      if (filters?.limit) {
        query += `&limit=${filters.limit}`;
      }
      if (filters?.offset) {
        query += `&offset=${filters.offset}`;
      }
      
      // Add user information
      query += `&select=*,created_by_user:created_by(full_name,email)`;
      
      const response = await api.get(query);
      // console.log('✅ Standalone equipment activity logs fetched successfully:', response.data);
      return response.data;
    } catch (error) {
      console.error('❌ Error fetching standalone equipment activity logs:', error);
      throw error;
    }
  },

  // ============================================================================
  // VDCR ACTIVITY LOGS
  // ============================================================================

  // Log VDCR activity
  async logVDCRActivity(data: {
    projectId: string;
    vdcrId?: string;
    activityType: string;
    actionDescription: string;
    fieldName?: string;
    oldValue?: string;
    newValue?: string;
    metadata?: any;
    createdBy: string;
  }) {
    try {
      // console.log('📝 logVDCRActivity called with:', data);
      const logData = {
        project_id: data.projectId,
        vdcr_id: data.vdcrId || null,
        activity_type: data.activityType,
        action_description: data.actionDescription,
        field_name: data.fieldName || null,
        old_value: data.oldValue || null,
        new_value: data.newValue || null,
        metadata: data.metadata || {},
        created_by: data.createdBy
      };

      // console.log('📝 Sending log data to API:', logData);
      const response = await api.post('/vdcr_activity_logs', logData);
      // console.log('✅ VDCR activity logged successfully:', response.data);
      return response.data;
    } catch (error: any) {
      console.error('❌ Error logging VDCR activity:', error);
      console.error('❌ Error response:', error?.response?.data);
      console.error('❌ Error status:', error?.response?.status);
      console.error('❌ Error message:', error?.message);
      // Don't throw - return null to prevent breaking main action
      return null;
    }
  },

  // Get VDCR activity logs by project
  async getVDCRActivityLogs(projectId: string, filters?: {
    vdcrId?: string;
    activityType?: string;
    userId?: string;
    dateFrom?: string;
    dateTo?: string;
    limit?: number;
    offset?: number;
  }) {
    try {
      // console.log('📋 Fetching VDCR activity logs for project:', projectId);
      
      // Build the select query first - this is critical for PostgREST
      let selectQuery = `select=*,created_by_user:created_by(full_name,email),vdcr_record:vdcr_id(document_name,status)`;
      
      // Start with the base query and select
      let query = `/vdcr_activity_logs?project_id=eq.${projectId}&${selectQuery}`;
      
      if (filters?.vdcrId) {
        query += `&vdcr_id=eq.${filters.vdcrId}`;
      }
      if (filters?.activityType) {
        query += `&activity_type=eq.${filters.activityType}`;
      }
      if (filters?.userId) {
        query += `&created_by=eq.${filters.userId}`;
      }
      if (filters?.dateFrom) {
        query += `&created_at=gte.${filters.dateFrom}`;
      }
      if (filters?.dateTo) {
        query += `&created_at=lte.${filters.dateTo}`;
      }
      
      // Add ordering
      query += `&order=created_at.desc`;
      
      if (filters?.limit) {
        query += `&limit=${filters.limit}`;
      }
      if (filters?.offset) {
        query += `&offset=${filters.offset}`;
      }
      
      // console.log('📋 activityApi: VDCR logs query:', query);
      const response = await api.get(query);
      const logs = Array.isArray(response.data) ? response.data : [];
      // console.log('📋 activityApi: VDCR activity logs fetched successfully:', {
      //   count: logs.length,
      //   firstLog: logs[0],
      //   allLogs: logs
      // });
      
      return logs;
    } catch (error: any) {
      console.error('❌ Error fetching VDCR activity logs:', error);
      console.error('❌ Error response:', error?.response?.data);
      console.error('❌ Error status:', error?.response?.status);
      console.error('❌ Error message:', error?.message);
      
      // If table doesn't exist (404 or 42P01), return empty array instead of throwing
      if (error?.response?.status === 404 || error?.message?.includes('does not exist') || error?.message?.includes('42P01')) {
        console.warn('⚠️ VDCR activity logs table may not exist. Please run the SQL schema file.');
        return [];
      }
      
      // For other errors, try a simpler query without foreign key relationships
      console.warn('⚠️ Retrying with simplified query (without foreign key relationships)...');
      try {
        let simpleQuery = `/vdcr_activity_logs?project_id=eq.${projectId}&select=*&order=created_at.desc`;
        if (filters?.limit) {
          simpleQuery += `&limit=${filters.limit}`;
        }
        const simpleResponse = await api.get(simpleQuery);
        const simpleLogs = Array.isArray(simpleResponse.data) ? simpleResponse.data : [];
        // console.log('✅ VDCR activity logs fetched with simplified query:', simpleLogs.length, 'logs');
        return simpleLogs;
      } catch (retryError) {
        console.error('❌ Error with simplified query as well:', retryError);
        return [];
      }
    }
  }
};

export default activityApi;
