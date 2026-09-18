// ============================================
// CONFIG SUPABASE — Remplacez vos clés ici
// ============================================
const SUPABASE_URL = 'https://qhgdtimwoqgpkivmpbgy.supabase.co';           // https://xxxxxxxx.supabase.co
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFoZ2R0aW13b3FncGtpdm1wYmd5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE4ODEyNjQsImV4cCI6MjA4NzQ1NzI2NH0.H_dgAxTsPvZHnvq6O9bwhWbmZ7g8EDNR4-BKyxll2Ek'; // eyJxxxxxxxxxxxxxxxx

const { createClient } = supabase;
const db = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Alias global
window.supabase = db;

// Auth check
function checkAuth() {
  if (sessionStorage.getItem('admin_auth') !== 'true') {
    window.location.href = 'index.html';
  }
}

function logout() {
  sessionStorage.removeItem('admin_auth');
  window.location.href = 'index.html';
}