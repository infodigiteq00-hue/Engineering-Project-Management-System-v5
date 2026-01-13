# RLS Deployment Order - All Tables

## ✅ Complete List of RLS Files Created

### **Core Foundation Files (Run FIRST - Dependencies)**
1. `RLS_FIX_USERS_TABLE.sql` - Users table + Helper functions (`is_super_admin`, `get_user_firm_id`, `is_firm_admin`)
2. `RLS_PROJECT_MEMBERS_TABLE.sql` - Project members table + `is_assigned_to_project()` function
3. `RLS_PROJECTS_TABLE.sql` - Projects table
4. `RLS_INVITES_TABLE.sql` - Invites table
5. `RLS_ACTIVITY_LOGS_BASIC.sql` - Activity logs tables (equipment, standalone, vdcr)

### **Equipment Tables (Project-based)**
6. `RLS_EQUIPMENT_TABLE.sql` - Equipment table
7. `RLS_EQUIPMENT_DOCUMENTS_TABLE.sql` - Equipment documents
8. `RLS_EQUIPMENT_PROGRESS_ENTRIES_TABLE.sql` - Equipment progress entries
9. `RLS_EQUIPMENT_PROGRESS_IMAGES_TABLE.sql` - Equipment progress images
10. `RLS_EQUIPMENT_TEAM_POSITIONS_TABLE.sql` - Equipment team positions

### **Standalone Equipment Tables (Created-by based)**
11. `RLS_STANDALONE_EQUIPMENT_TABLE.sql` - Standalone equipment
12. `RLS_STANDALONE_EQUIPMENT_DOCUMENTS_TABLE.sql` - Standalone equipment documents
13. `RLS_STANDALONE_EQUIPMENT_PROGRESS_ENTRIES_TABLE.sql` - Standalone equipment progress entries
14. `RLS_STANDALONE_EQUIPMENT_PROGRESS_IMAGES_TABLE.sql` - Standalone equipment progress images
15. `RLS_STANDALONE_EQUIPMENT_TEAM_POSITIONS_TABLE.sql` - Standalone equipment team positions

### **VDCR Tables (Project-based)**
16. `RLS_VDCR_RECORDS_TABLE.sql` - VDCR records
17. `RLS_VDCR_DOCUMENTS_TABLE.sql` - VDCR documents
18. `RLS_VDCR_DOCUMENT_HISTORY_TABLE.sql` - VDCR document history
19. `RLS_VDCR_REVISION_EVENTS_TABLE.sql` - VDCR revision events

### **Project Documents Tables (Project-based)**
20. `RLS_UNPRICED_PO_DOCUMENTS_TABLE.sql` - Unpriced PO documents
21. `RLS_DESIGN_INPUTS_DOCUMENTS_TABLE.sql` - Design inputs documents
22. `RLS_CLIENT_REFERENCE_DOCUMENTS_TABLE.sql` - Client reference documents
23. `RLS_OTHER_DOCUMENTS_TABLE.sql` - Other documents

---

## 📋 Deployment Order

### **Step 1: Foundation (MUST RUN FIRST)**
Run these files in order - they create helper functions used by all other tables:

```sql
1. RLS_FIX_USERS_TABLE.sql
2. RLS_PROJECT_MEMBERS_TABLE.sql
3. RLS_PROJECTS_TABLE.sql
4. RLS_INVITES_TABLE.sql
5. RLS_ACTIVITY_LOGS_BASIC.sql
```

### **Step 2: Equipment Tables**
Run these after foundation files:

```sql
6. RLS_EQUIPMENT_TABLE.sql
7. RLS_EQUIPMENT_DOCUMENTS_TABLE.sql
8. RLS_EQUIPMENT_PROGRESS_ENTRIES_TABLE.sql
9. RLS_EQUIPMENT_PROGRESS_IMAGES_TABLE.sql
10. RLS_EQUIPMENT_TEAM_POSITIONS_TABLE.sql
```

### **Step 3: Standalone Equipment Tables**
Run these after foundation files (can run parallel with Step 2):

```sql
11. RLS_STANDALONE_EQUIPMENT_TABLE.sql
12. RLS_STANDALONE_EQUIPMENT_DOCUMENTS_TABLE.sql
13. RLS_STANDALONE_EQUIPMENT_PROGRESS_ENTRIES_TABLE.sql
14. RLS_STANDALONE_EQUIPMENT_PROGRESS_IMAGES_TABLE.sql
15. RLS_STANDALONE_EQUIPMENT_TEAM_POSITIONS_TABLE.sql
```

### **Step 4: VDCR Tables**
Run these after foundation files (can run parallel with Steps 2-3):

```sql
16. RLS_VDCR_RECORDS_TABLE.sql
17. RLS_VDCR_DOCUMENTS_TABLE.sql
18. RLS_VDCR_DOCUMENT_HISTORY_TABLE.sql
19. RLS_VDCR_REVISION_EVENTS_TABLE.sql
```

### **Step 5: Project Documents Tables**
Run these after foundation files (can run parallel with Steps 2-4):

```sql
20. RLS_UNPRICED_PO_DOCUMENTS_TABLE.sql
21. RLS_DESIGN_INPUTS_DOCUMENTS_TABLE.sql
22. RLS_CLIENT_REFERENCE_DOCUMENTS_TABLE.sql
23. RLS_OTHER_DOCUMENTS_TABLE.sql
```

---

## 🚀 Quick Deployment Steps

1. **Open Supabase Dashboard** → SQL Editor
2. **Copy and paste each file** in the order listed above
3. **Run each file** one by one
4. **Check for errors** - if any, fix and re-run
5. **Test the application** after all files are deployed

---

## ⚠️ Important Notes

- **Dependencies**: Files in Step 1 MUST be run first as they create helper functions
- **Safe to re-run**: All files use `DROP POLICY IF EXISTS` so they're safe to run multiple times
- **No data loss**: RLS only adds security policies, doesn't modify existing data
- **Test after deployment**: Verify that users can still access their data correctly

---

## 📊 Total Files: 23 RLS Files

All tables now have comprehensive Row Level Security policies implemented!

