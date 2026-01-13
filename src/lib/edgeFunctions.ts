// Edge Functions Client
// Provides secure client-side functions to call Supabase Edge Functions
// This ensures sensitive keys (like service role key) are never exposed to frontend

import { supabase } from './supabase'

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL || 'https://ypdlbqrcxnugrvllbmsi.supabase.co'

// Helper function to convert File to base64
function fileToBase64(file: File): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader()
    reader.onload = () => {
      if (typeof reader.result === 'string') {
        resolve(reader.result)
      } else {
        reject(new Error('Failed to convert file to base64'))
      }
    }
    reader.onerror = reject
    reader.readAsDataURL(file)
  })
}

interface UploadFileParams {
  bucket: string
  filePath: string
  file: File
}

export async function uploadFileViaEdgeFunction({
  bucket,
  filePath,
  file
}: UploadFileParams): Promise<string> {
  try {
    // Get current session for authentication
    const { data: { session } } = await supabase.auth.getSession()

    if (!session?.access_token) {
      throw new Error('User not authenticated')
    }

    // Convert file to base64
    const fileData = await fileToBase64(file)

    // Call edge function
    const response = await fetch(`${SUPABASE_URL}/functions/v1/upload-file`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${session.access_token}`,
        'apikey': import.meta.env.VITE_SUPABASE_ANON_KEY || ''
      },
      body: JSON.stringify({
        bucket,
        filePath,
        fileData,
        contentType: file.type,
        fileName: file.name
      })
    })

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({ error: 'Unknown error' }))
      throw new Error(errorData.error || `Upload failed: ${response.status}`)
    }

    const result = await response.json()
    return result.publicUrl
  } catch (error) {
    console.error('Edge function upload error:', error)
    throw error
  }
}

