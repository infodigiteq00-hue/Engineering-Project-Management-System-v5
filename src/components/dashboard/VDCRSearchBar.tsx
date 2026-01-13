import React from "react";
import { Input } from "@/components/ui/input";
import { Search, X } from "lucide-react";
import { Button } from "@/components/ui/button";

interface VDCRSearchBarProps {
  searchQuery: string;
  onSearchChange: (query: string) => void;
  resultCount?: number;
  totalCount?: number;
}

const VDCRSearchBar: React.FC<VDCRSearchBarProps> = ({
  searchQuery,
  onSearchChange,
  resultCount,
  totalCount
}) => {
  return (
    <div className="mb-4">
      <div className="relative">
        <div className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400">
          <Search className="w-5 h-5" />
        </div>
        <Input
          type="text"
          placeholder="Search by document name, equipment tag, revision, status, client doc, internal doc, or any field..."
          value={searchQuery}
          onChange={(e) => onSearchChange(e.target.value)}
          className="pl-10 pr-10 h-12 text-base border-2 border-gray-300 focus:border-blue-500 rounded-lg shadow-sm focus:shadow-md transition-all duration-200"
        />
        {searchQuery && (
          <Button
            variant="ghost"
            size="sm"
            onClick={() => onSearchChange("")}
            className="absolute right-2 top-1/2 transform -translate-y-1/2 h-8 w-8 p-0 hover:bg-gray-100 rounded-full"
          >
            <X className="w-4 h-4 text-gray-500" />
          </Button>
        )}
      </div>
      {searchQuery && (
        <div className="mt-2 text-sm text-gray-600 flex items-center gap-2">
          <span className="font-medium">
            {resultCount !== undefined && totalCount !== undefined ? (
              <>
                Showing <span className="text-blue-600 font-bold">{resultCount}</span> of{" "}
                <span className="text-gray-700 font-bold">{totalCount}</span> records
              </>
            ) : (
              "Searching..."
            )}
          </span>
        </div>
      )}
    </div>
  );
};

export default VDCRSearchBar;

