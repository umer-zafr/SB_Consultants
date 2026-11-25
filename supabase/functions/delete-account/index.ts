import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    if (!supabaseUrl || !serviceRoleKey) {
      return new Response(
        JSON.stringify({ error: "Missing Supabase configuration" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey);

    // Authenticate the caller from Authorization Bearer token
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Authorization header is required." }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const token = authHeader.replace("Bearer ", "").trim();
    const { data: { user }, error: userError } = await supabaseAdmin.auth.getUser(token);

    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: "Unauthorized: Invalid or expired session token." }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const targetUserId = user.id;

    // 1. Delete dependent user data from public tables
    try {
      await supabaseAdmin.from("applications").delete().eq("user_id", targetUserId);
      await supabaseAdmin.from("payments").delete().eq("user_id", targetUserId);
      await supabaseAdmin.from("user_directory_unlocks").delete().eq("user_id", targetUserId);
      await supabaseAdmin.from("user_documents").delete().eq("user_id", targetUserId);
      await supabaseAdmin.from("saved_items").delete().eq("user_id", targetUserId);
      await supabaseAdmin.from("consultancy_bookings").delete().eq("user_id", targetUserId);
      await supabaseAdmin.from("application_feedback").delete().eq("user_id", targetUserId);
      await supabaseAdmin.from("profiles").delete().eq("id", targetUserId);
    } catch (dbErr) {
      console.warn("Notice during cascaded cleanup:", dbErr);
    }

    // 2. Permanently delete the user from auth.users
    const { error: deleteAuthError } = await supabaseAdmin.auth.admin.deleteUser(targetUserId);

    if (deleteAuthError) {
      console.error("Failed to delete user from auth:", deleteAuthError);
      return new Response(
        JSON.stringify({ error: `Failed to permanently delete user: ${deleteAuthError.message}` }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: "Account permanently deleted successfully.",
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err: any) {
    console.error("Fatal delete account error:", err);
    return new Response(
      JSON.stringify({ error: err?.message || "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
