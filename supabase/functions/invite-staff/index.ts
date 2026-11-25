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

    // =========================================================================
    // SECURITY CHECK: STRICT AUTHENTICATION & SUPER ADMIN AUTHORIZATION ENFORCEMENT
    // =========================================================================
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Access Denied: Missing Authorization header." }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const token = authHeader.replace("Bearer ", "").trim();
    const { data: { user: callerUser }, error: authErr } = await supabaseAdmin.auth.getUser(token);

    if (authErr || !callerUser) {
      return new Response(
        JSON.stringify({ error: "Access Denied: Invalid or expired authentication token." }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Verify that caller's profile exists and has role 'admin'
    const { data: callerProfile, error: profileErr } = await supabaseAdmin
      .from("profiles")
      .select("id, role, email")
      .eq("id", callerUser.id)
      .maybeSingle();

    if (profileErr || !callerProfile || callerProfile.role !== "admin") {
      return new Response(
        JSON.stringify({
          error: "Forbidden: Only active Super Administrators can invite staff or assign administrative roles.",
        }),
        { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const inviterId = callerUser.id;

    const body = await req.json().catch(() => ({}));
    const email = (body.email ?? "").toString().trim().toLowerCase();
    const role = (body.role ?? "consultant").toString().trim().toLowerCase();
    const fullName = (body.full_name ?? body.fullName ?? "").toString().trim();
    const password = (body.password ?? "").toString().trim();
    const redirectTo = body.redirect_url ?? body.redirectTo ?? "https://sbconsultant.site/admin";

    if (!email || !email.includes("@")) {
      return new Response(
        JSON.stringify({ error: "A valid email address is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (role !== "admin" && role !== "consultant") {
      return new Response(
        JSON.stringify({ error: "Role must be 'admin' or 'consultant'" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // =========================================================================
    // OPTION 1: DIRECT ACCOUNT CREATION WITH PASSWORD (Pre-confirmed staff login)
    // =========================================================================
    if (password.length > 0) {
      if (password.length < 8) {
        return new Response(
          JSON.stringify({ error: "Password must be at least 8 characters long for administrative security." }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      // Check if user already exists in auth.users
      const { data: { users }, error: listErr } = await supabaseAdmin.auth.admin.listUsers();
      const existingAuthUser = (users ?? []).find(
        (u) => u.email?.toLowerCase() === email
      );

      let targetUserId: string;

      if (existingAuthUser) {
        // User already exists in auth -> Update password and metadata
        targetUserId = existingAuthUser.id;
        const { error: updateErr } = await supabaseAdmin.auth.admin.updateUserById(
          targetUserId,
          {
            password: password,
            email_confirm: true,
            user_metadata: {
              ...(fullName ? { full_name: fullName, name: fullName } : {}),
              role: role,
            },
          }
        );
        if (updateErr) {
          throw new Error(`Failed to update user password: ${updateErr.message}`);
        }
      } else {
        // Create new active user with email pre-confirmed
        const { data: newUserData, error: createErr } = await supabaseAdmin.auth.admin.createUser({
          email: email,
          password: password,
          email_confirm: true,
          user_metadata: {
            full_name: fullName,
            name: fullName,
            role: role,
            invited_by: inviterId,
          },
        });
        if (createErr || !newUserData.user) {
          throw new Error(`Failed to create staff account: ${createErr?.message}`);
        }
        targetUserId = newUserData.user.id;
      }

      // Ensure profile is updated/created with correct role and full_name
      await supabaseAdmin.from("profiles").upsert({
        id: targetUserId,
        email: email,
        full_name: fullName,
        role: role,
        is_verified: true,
        updated_at: new Date().toISOString(),
      });

      // Mark any pending invitation as accepted
      try {
        await supabaseAdmin
          .from("staff_invitations")
          .update({ status: "accepted", updated_at: new Date().toISOString() })
          .ilike("email", email)
          .eq("status", "pending");
      } catch (_) {}

      // Log to audit log
      try {
        await supabaseAdmin.from("admin_audit_logs").insert({
          admin_id: inviterId,
          action: "create_staff_direct",
          entity_type: "user_role",
          entity_id: targetUserId,
          details: {
            email: email,
            role: role,
            full_name: fullName,
            mode: "direct_password",
            created_by_admin: callerProfile.email,
            timestamp: new Date().toISOString(),
          },
        });
      } catch (_) {}

      return new Response(
        JSON.stringify({
          success: true,
          is_instant: true,
          email_sent: false,
          user_id: targetUserId,
          email: email,
          full_name: fullName,
          role: role,
          message: `Staff account successfully created and authorized by administrator.`,
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // =========================================================================
    // INVITATION MODE (No password provided -> Generate invitation link)
    // =========================================================================
    const { data: existingProfile } = await supabaseAdmin
      .from("profiles")
      .select("id, email, role, full_name")
      .ilike("email", email)
      .maybeSingle();

    if (existingProfile) {
      await supabaseAdmin
        .from("profiles")
        .update({
          role,
          ...(fullName ? { full_name: fullName } : {}),
          updated_at: new Date().toISOString(),
        })
        .eq("id", existingProfile.id);

      await supabaseAdmin
        .from("staff_invitations")
        .update({ status: "accepted", updated_at: new Date().toISOString() })
        .ilike("email", email)
        .eq("status", "pending");

      try {
        await supabaseAdmin.from("admin_audit_logs").insert({
          admin_id: inviterId,
          action: "elevate_staff_role",
          entity_type: "user_role",
          entity_id: existingProfile.id,
          details: {
            email: email,
            role: role,
            previous_role: existingProfile.role,
            created_by_admin: callerProfile.email,
            timestamp: new Date().toISOString(),
          },
        });
      } catch (_) {}

      return new Response(
        JSON.stringify({
          success: true,
          is_instant: true,
          email_sent: false,
          role,
          email,
          message: `User is already registered. Their account has been elevated to ${role.toUpperCase()}.`,
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Generate direct authentication invite link
    let inviteLink: string | null = null;
    try {
      const { data: linkData, error: linkErr } = await supabaseAdmin.auth.admin.generateLink({
        type: "invite",
        email: email,
        options: {
          redirectTo,
          data: { role, invited_by: inviterId },
        },
      });

      if (!linkErr && linkData?.properties?.action_link) {
        inviteLink = linkData.properties.action_link;
      }
    } catch (e) {
      console.error("generateLink error:", e);
    }

    // Upsert into public.staff_invitations including invite_link
    const { data: existingInvite } = await supabaseAdmin
      .from("staff_invitations")
      .select("id")
      .ilike("email", email)
      .eq("status", "pending")
      .maybeSingle();

    if (existingInvite) {
      await supabaseAdmin
        .from("staff_invitations")
        .update({
          role,
          invited_by: inviterId,
          invite_link: inviteLink,
          updated_at: new Date().toISOString(),
        })
        .eq("id", existingInvite.id);
    } else {
      await supabaseAdmin
        .from("staff_invitations")
        .insert({
          email,
          role,
          invited_by: inviterId,
          invite_link: inviteLink,
          status: "pending",
        });
    }

    // Attempt direct email sending via inviteUserByEmail
    let emailSent = false;
    let emailError: string | null = null;

    try {
      const { error: inviteErr } = await supabaseAdmin.auth.admin.inviteUserByEmail(
        email,
        {
          redirectTo,
          data: {
            role,
            invited_by: inviterId,
          },
        }
      );

      if (inviteErr) {
        emailError = inviteErr.message;
      } else {
        emailSent = true;
      }
    } catch (err: any) {
      emailError = err?.message ?? "Error sending invite email";
    }

    try {
      await supabaseAdmin.from("admin_audit_logs").insert({
        admin_id: inviterId,
        action: "invite_staff",
        entity_type: "staff_invitation",
        details: {
          email: email,
          role: role,
          email_sent: emailSent,
          created_by_admin: callerProfile.email,
          timestamp: new Date().toISOString(),
        },
      });
    } catch (_) {}

    return new Response(
      JSON.stringify({
        success: true,
        is_instant: false,
        email_sent: emailSent,
        email_error: emailError,
        invite_link: inviteLink,
        role,
        email,
        message: emailSent
          ? `Official invitation email successfully sent to ${email}!`
          : `Invitation created for ${email}. Email dispatch notice: ${emailError}. You can share the direct activation link with them.`,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error: any) {
    console.error("Fatal error in invite-staff:", error);
    return new Response(
      JSON.stringify({ error: error?.message || "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
