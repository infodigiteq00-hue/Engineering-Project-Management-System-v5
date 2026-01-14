import React, { createContext, useContext, useEffect, useState } from 'react';
import { supabase } from '@/lib/supabase';
import { User } from '@supabase/supabase-js';

interface AuthContextType {
  user: User | null;
  userRole: string | null;
  userName: string | null;
  firmId: string | null;
  loading: boolean;
  signOut: () => Promise<void>;
  refreshUserData: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

interface AuthProviderProps {
  children: React.ReactNode;
}

export const AuthProvider: React.FC<AuthProviderProps> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [userRole, setUserRole] = useState<string | null>(null);
  const [userName, setUserName] = useState<string | null>(null);
  const [firmId, setFirmId] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Get initial session with better error handling
    const initializeAuth = async () => {
      try {
        const { data: { session }, error } = await supabase.auth.getSession();
        
        if (error) {
          console.error('Session error:', error);
          setLoading(false);
          return;
        }

        setUser(session?.user ?? null);
        if (session?.user) {
          await fetchUserData(session.user.id);
          // console.log('✅ AuthContext: fetchUserData completed', { firmId, userRole });
          
          // ALWAYS restore from localStorage as backup - ensures state is always set
          // This handles cases where fetchUserData returns early or fails silently
          const storedRole = localStorage.getItem('userRole');
          const storedName = localStorage.getItem('userName');
          const storedFirmId = localStorage.getItem('firmId');
          
          if (storedRole && storedName && storedFirmId) {
            // Always set from localStorage to ensure state is populated
            // fetchUserData might have set it, but this ensures it's definitely set
            setUserRole(storedRole);
            setUserName(storedName);
            setFirmId(storedFirmId);
            // console.log('✅ AuthContext: Ensured state from localStorage', { storedFirmId, storedRole });
          }
        } else {
          // Try to restore from localStorage if no session
          const storedRole = localStorage.getItem('userRole');
          const storedName = localStorage.getItem('userName');
          const storedFirmId = localStorage.getItem('firmId');
          
          if (storedRole && storedName) {
            setUserRole(storedRole);
            setUserName(storedName);
            setFirmId(storedFirmId);
            // console.log('✅ AuthContext: Restored from localStorage (no session)', { storedFirmId, storedRole });
          }
        }
      } catch (error) {
        console.error('Auth initialization error:', error);
        // Try localStorage as fallback even on error
        const storedRole = localStorage.getItem('userRole');
        const storedName = localStorage.getItem('userName');
        const storedFirmId = localStorage.getItem('firmId');
        
        if (storedRole && storedName && storedFirmId) {
          setUserRole(storedRole);
          setUserName(storedName);
          setFirmId(storedFirmId);
          // console.log('✅ AuthContext: Restored from localStorage after error', { storedFirmId, storedRole });
        }
      } finally {
        // Always restore from localStorage before setting loading to false
        // This ensures state is set even if fetchUserData failed
        const storedRole = localStorage.getItem('userRole');
        const storedName = localStorage.getItem('userName');
        const storedFirmId = localStorage.getItem('firmId');
        
        if (storedRole && storedName && storedFirmId) {
          setUserRole(storedRole);
          setUserName(storedName);
          setFirmId(storedFirmId);
          // console.log('✅ AuthContext: Final localStorage restore in finally block', { storedFirmId, storedRole });
        }
        
        // Always set loading to false
        // console.log('✅ AuthContext: Setting loading to false', { 
        //   firmId: storedFirmId || firmId, 
        //   userRole: storedRole || userRole 
        // });
        setLoading(false);
      }
    };

    initializeAuth();

    // Listen for auth changes
    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange(async (event, session) => {
      // console.log('Auth state changed:', event, session?.user?.id);
      
      setUser(session?.user ?? null);
      if (session?.user) {
        await fetchUserData(session.user.id);
      } else {
        // Clear user data on sign out
        setUserRole(null);
        setUserName(null);
        setFirmId(null);
        // Clear cache on logout
        const { clearCache } = await import('@/utils/cache');
        clearCache();
        localStorage.clear();
      }
      setLoading(false);
    });

    return () => subscription.unsubscribe();
  }, []);

  const fetchUserData = async (userId: string) => {
    try {
      // First try to get the current user's email from auth
      const { data: { user: authUser } } = await supabase.auth.getUser();
      
      if (!authUser?.email) {
        console.error('⚠️ No authenticated user email found - trying localStorage fallback');
        // Try localStorage as fallback
        const storedRole = localStorage.getItem('userRole');
        const storedName = localStorage.getItem('userName');
        const storedFirmId = localStorage.getItem('firmId');
        
        if (storedRole && storedName && storedFirmId) {
          setUserRole(storedRole);
          setUserName(storedName);
          setFirmId(storedFirmId);
          // console.log('✅ AuthContext: Using localStorage fallback (no email)', { storedFirmId, storedRole });
        }
        return;
      }

      // Search by email instead of ID to handle ID mismatches
      const { data: userData, error } = await supabase
        .from('users')
        .select('role, full_name, firm_id, is_active, id, email')
        .eq('email', authUser.email)
        .maybeSingle(); // Use maybeSingle() instead of single() to handle 0 rows gracefully
      
      const typedUserData = userData as any;

      if (error) {
        console.error('⚠️ Error fetching user data:', error, '- trying localStorage fallback');
        // Try localStorage as fallback
        const storedRole = localStorage.getItem('userRole');
        const storedName = localStorage.getItem('userName');
        const storedFirmId = localStorage.getItem('firmId');
        
        if (storedRole && storedName && storedFirmId) {
          setUserRole(storedRole);
          setUserName(storedName);
          setFirmId(storedFirmId);
          // console.log('✅ AuthContext: Using localStorage fallback (error)', { storedFirmId, storedRole });
        }
        return;
      }

      // Handle case where no user data is found
      if (!typedUserData) {
        console.warn('No user data found in database for email:', authUser.email);
        return;
      }

      if (!typedUserData.is_active) {
        console.warn('User account is inactive');
        return;
      }

      setUserRole(typedUserData.role);
      setUserName(typedUserData.full_name);
      setFirmId(typedUserData.firm_id);

      // Store in localStorage
      localStorage.setItem('userRole', typedUserData.role);
      localStorage.setItem('userName', typedUserData.full_name);
      localStorage.setItem('firmId', typedUserData.firm_id || '');
      localStorage.setItem('userId', userId);
      
      // Also store as userData object to match what Index.tsx expects
      // This ensures that after page refresh, Index.tsx can find userData.firm_id
      const userDataObject = {
        id: userId,
        role: typedUserData.role,
        full_name: typedUserData.full_name,
        email: typedUserData.email || authUser.email,
        firm_id: typedUserData.firm_id,
        is_active: typedUserData.is_active
      };
      localStorage.setItem('userData', JSON.stringify(userDataObject));
      
      // console.log('✅ AuthContext: User data loaded and stored', { 
      //   firmId: typedUserData.firm_id, 
      //   role: typedUserData.role,
      //   hasUserData: !!localStorage.getItem('userData')
      // });
    } catch (error) {
      console.error('Error in fetchUserData:', error);
    }
  };

  const refreshUserData = async () => {
    if (user) {
      await fetchUserData(user.id);
    }
  };

  const signOut = async () => {
    try {
      await supabase.auth.signOut();
      setUser(null);
      setUserRole(null);
      setUserName(null);
      setFirmId(null);
      // Clear cache on logout
      const { clearCache } = await import('@/utils/cache');
      clearCache();
      localStorage.clear();
    } catch (error) {
      console.error('Error signing out:', error);
    }
  };

  const value = {
    user,
    userRole,
    userName,
    firmId,
    loading,
    signOut,
    refreshUserData,
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};