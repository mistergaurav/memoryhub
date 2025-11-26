"""
Database index management for optimal query performance.
Creates indexes for frequently queried fields across all collections.
"""
from app.db.mongodb import get_collection


async def create_all_indexes():
    """Create all database indexes for optimal performance"""
    
    # User collection indexes with explicit names to prevent conflicts
    await get_collection("users").create_index("email", unique=True, name="email_unique")
    await get_collection("users").create_index("username", unique=True, sparse=True, name="username_unique_sparse")
    await get_collection("users").create_index("created_at", name="created_at_1")
    # Text index for user search on full_name and email (for efficient search queries)
    await get_collection("users").create_index([("full_name", "text"), ("email", "text"), ("username", "text")], name="users_text_search")
    
    # Family relationships indexes
    await get_collection("family_relationships").create_index([("user_id", 1), ("relation_type", 1)])
    await get_collection("family_relationships").create_index("related_user_id")
    await get_collection("family_relationships").create_index("created_at")
    
    # Family circles indexes
    await get_collection("family_circles").create_index("owner_id")
    await get_collection("family_circles").create_index("member_ids")
    await get_collection("family_circles").create_index([("owner_id", 1), ("created_at", -1)])
    await get_collection("family_circles").create_index("circle_type")
    
    # Family invitations indexes
    await get_collection("family_invitations").create_index("token", unique=True)
    await get_collection("family_invitations").create_index("invited_by")
    await get_collection("family_invitations").create_index([("expires_at", 1), ("status", 1)])
    await get_collection("family_invitations").create_index("email")
    
    # Family albums indexes
    await get_collection("family_albums").create_index("created_by")
    await get_collection("family_albums").create_index("member_ids")
    await get_collection("family_albums").create_index([("privacy", 1), ("updated_at", -1)])
    await get_collection("family_albums").create_index("family_circle_ids")
    
    # Family calendar events indexes (collection is named "family_events")
    await get_collection("family_events").create_index("created_by")
    await get_collection("family_events").create_index("attendee_ids")
    await get_collection("family_events").create_index([("event_date", 1), ("event_type", 1)])
    await get_collection("family_events").create_index("family_circle_ids")
    await get_collection("family_events").create_index([("reminder_sent", 1), ("event_date", 1)])
    
    # Memories collection indexes
    await get_collection("memories").create_index("user_id")
    await get_collection("memories").create_index([("user_id", 1), ("created_at", -1)])
    await get_collection("memories").create_index("privacy")
    await get_collection("memories").create_index("tags")
    
    # Collections/Albums indexes
    await get_collection("collections").create_index("user_id")
    await get_collection("collections").create_index([("user_id", 1), ("updated_at", -1)])
    await get_collection("collections").create_index("privacy")
    
    # Sharing links indexes
    await get_collection("share_links").create_index("token", unique=True)
    await get_collection("share_links").create_index("created_by")
    await get_collection("share_links").create_index([("expires_at", 1), ("is_active", 1)])
    
    # Audit logs indexes (for GDPR compliance)
    await get_collection("audit_logs").create_index([("user_id", 1), ("timestamp", -1)])
    await get_collection("audit_logs").create_index("event_type")
    await get_collection("audit_logs").create_index("timestamp")
    
    # Notifications indexes
    await get_collection("notifications").create_index([("user_id", 1), ("read", 1), ("created_at", -1)])
    await get_collection("notifications").create_index("created_at")
    
    # Genealogy persons indexes
    await get_collection("genealogy_persons").create_index("family_id")
    await get_collection("genealogy_persons").create_index([("family_id", 1), ("linked_user_id", 1)], unique=True, sparse=True)
    await get_collection("genealogy_persons").create_index([("family_id", 1), ("created_at", -1)])
    await get_collection("genealogy_persons").create_index("source")
    
    # Genealogy relationships indexes
    await get_collection("genealogy_relationships").create_index("family_id")
    await get_collection("genealogy_relationships").create_index([("person1_id", 1), ("relationship_type", 1)])
    await get_collection("genealogy_relationships").create_index([("person2_id", 1), ("relationship_type", 1)])
    await get_collection("genealogy_relationships").create_index([("family_id", 1), ("created_at", -1)])
    
    # Genealogy tree memberships indexes (for shared trees)
    await get_collection("genealogy_tree_memberships").create_index([("tree_id", 1), ("user_id", 1)], unique=True)
    await get_collection("genealogy_tree_memberships").create_index("user_id")
    await get_collection("genealogy_tree_memberships").create_index([("tree_id", 1), ("role", 1)])
    
    # Genealogy invitation links indexes
    await get_collection("genealogy_invite_links").create_index("token", unique=True)
    await get_collection("genealogy_invite_links").create_index([("family_id", 1), ("status", 1)])
    await get_collection("genealogy_invite_links").create_index("person_id")
    await get_collection("genealogy_invite_links").create_index([("expires_at", 1), ("status", 1)])
    
    # Health records indexes
    await get_collection("health_records").create_index("family_id")
    await get_collection("health_records").create_index("family_member_id")
    await get_collection("health_records").create_index([("family_id", 1), ("subject_type", 1)])
    await get_collection("health_records").create_index("subject_user_id")
    await get_collection("health_records").create_index("subject_family_member_id")
    await get_collection("health_records").create_index("subject_friend_circle_id")
    await get_collection("health_records").create_index("assigned_user_ids")
    await get_collection("health_records").create_index([("family_id", 1), ("date", -1)])
    await get_collection("health_records").create_index([("family_id", 1), ("record_type", 1)])
    await get_collection("health_records").create_index("created_by")
    
    # Health record reminders indexes (compound index for efficient queries)
    await get_collection("health_record_reminders").create_index("record_id")
    await get_collection("health_record_reminders").create_index([("assigned_user_id", 1), ("status", 1), ("due_at", 1)])
    await get_collection("health_record_reminders").create_index([("assigned_user_id", 1), ("due_at", 1)])
    await get_collection("health_record_reminders").create_index([("status", 1), ("due_at", 1)])
    await get_collection("health_record_reminders").create_index("created_by")
    
    # Vaccination records indexes
    await get_collection("vaccination_records").create_index("family_id")
    await get_collection("vaccination_records").create_index("family_member_id")
    await get_collection("vaccination_records").create_index([("family_id", 1), ("date_administered", -1)])
    
    # User milestones indexes (timeline system)
    await get_collection("user_milestones").create_index([("owner_id", 1), ("created_at", -1)])
    await get_collection("user_milestones").create_index([("audience_scope", 1), ("created_at", -1)])
    await get_collection("user_milestones").create_index("owner_id")
    await get_collection("user_milestones").create_index("circle_ids")
    
    # Milestone comments indexes
    await get_collection("milestone_comments").create_index([("milestone_id", 1), ("created_at", 1)])
    await get_collection("milestone_comments").create_index("milestone_id")
    await get_collection("milestone_comments").create_index("author_id")
    await get_collection("milestone_comments").create_index("parent_comment_id")
    
    # Milestone reactions indexes
    await get_collection("milestone_reactions").create_index([("milestone_id", 1), ("actor_id", 1)], unique=True)
    await get_collection("milestone_reactions").create_index([("milestone_id", 1), ("created_at", -1)])
    await get_collection("milestone_reactions").create_index("milestone_id")
    await get_collection("milestone_reactions").create_index("actor_id")
    
    # Relationships indexes (dual-row pattern)
    await get_collection("relationships").create_index([("user_id", 1), ("status", 1)])
    await get_collection("relationships").create_index([("user_id", 1), ("relationship_type", 1)])
    await get_collection("relationships").create_index("user_id")
    await get_collection("relationships").create_index("related_user_id")
    await get_collection("relationships").create_index([("user_id", 1), ("related_user_id", 1)])
    await get_collection("relationships").create_index("requester_id")
    
    print("✅ All database indexes created successfully")


async def drop_all_indexes():
    """Drop all custom indexes (useful for testing)"""
    collections = [
        "users", "family_relationships", "family_circles", "family_invitations",
        "family_albums", "family_calendar_events", "memories", "collections",
        "share_links", "audit_logs", "notifications", "genealogy_persons", "genealogy_relationships"
    ]
    
    for collection_name in collections:
        await get_collection(collection_name).drop_indexes()
    
    print("✅ All custom indexes dropped")
