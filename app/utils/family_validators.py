"""
Family Hub validators - consolidated validation logic for Family Hub features.
Eliminates code duplication across Family Hub modules.
"""
from typing import List, Optional, Dict, Any
from bson import ObjectId
from fastapi import HTTPException
from app.db.mongodb import get_collection
from app.utils.audit_logger import log_audit_event


async def validate_family_ownership(
    user_id: str,
    family_id: str,
    collection_name: str = "family_circles"
) -> Dict[str, Any]:
    """
    Validate that a user owns a family resource.
    
    Args:
        user_id: String representation of user ID
        family_id: String representation of family resource ID
        collection_name: MongoDB collection name (default: family_circles)
        
    Returns:
        The family resource document
        
    Raises:
        HTTPException: If validation fails (400, 403, or 404)
    """
    try:
        user_oid = ObjectId(user_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid user ID")
    
    try:
        family_oid = ObjectId(family_id)
    except Exception:
        raise HTTPException(status_code=400, detail=f"Invalid {collection_name.replace('_', ' ')} ID")
    
    collection = get_collection(collection_name)
    family_doc = await collection.find_one({"_id": family_oid})
    
    if not family_doc:
        raise HTTPException(
            status_code=404,
            detail=f"{collection_name.replace('_', ' ').title()} not found"
        )
    
    if family_doc.get("owner_id") != user_oid:
        raise HTTPException(
            status_code=403,
            detail="You do not have permission to access this resource"
        )
    
    return family_doc


async def validate_family_member_access(
    user_id: str,
    family_id: str,
    collection_name: str = "family_circles"
) -> Dict[str, Any]:
    """
    Validate that a user has member access to a family resource (owner or member).
    
    Args:
        user_id: String representation of user ID
        family_id: String representation of family resource ID
        collection_name: MongoDB collection name (default: family_circles)
        
    Returns:
        The family resource document
        
    Raises:
        HTTPException: If validation fails (400, 403, or 404)
    """
    try:
        user_oid = ObjectId(user_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid user ID")
    
    try:
        family_oid = ObjectId(family_id)
    except Exception:
        raise HTTPException(status_code=400, detail=f"Invalid {collection_name.replace('_', ' ')} ID")
    
    collection = get_collection(collection_name)
    family_doc = await collection.find_one({"_id": family_oid})
    
    if not family_doc:
        raise HTTPException(
            status_code=404,
            detail=f"{collection_name.replace('_', ' ').title()} not found"
        )
    
    is_owner = family_doc.get("owner_id") == user_oid
    is_member = user_oid in family_doc.get("member_ids", [])
    
    if not (is_owner or is_member):
        raise HTTPException(
            status_code=403,
            detail="You do not have access to this resource"
        )
    
    return family_doc


def validate_object_id_list(
    ids: List[str],
    field_name: str = "IDs"
) -> List[ObjectId]:
    """
    Validate and convert a list of string IDs to ObjectIds.
    
    Args:
        ids: List of string representations of ObjectIds
        field_name: Name of the field for error messages
        
    Returns:
        List of valid ObjectIds
        
    Raises:
        HTTPException: If any ID in the list is invalid (400)
    """
    if not ids:
        return []
    
    valid_ids = []
    invalid_ids = []
    
    for idx, id_str in enumerate(ids):
        try:
            valid_ids.append(ObjectId(id_str))
        except Exception:
            invalid_ids.append(f"{field_name}[{idx}]='{id_str}'")
    
    if invalid_ids:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid {field_name}: {', '.join(invalid_ids)}"
        )
    
    return valid_ids


async def validate_user_exists(user_id: str, field_name: str = "user") -> Dict[str, Any]:
    """
    Validate that a user exists in the database.
    
    Args:
        user_id: String representation of user ID
        field_name: Name of the field for error messages
        
    Returns:
        User document
        
    Raises:
        HTTPException: If user doesn't exist or ID is invalid
    """
    try:
        user_oid = ObjectId(user_id)
    except Exception:
        raise HTTPException(status_code=400, detail=f"Invalid {field_name} ID")
    
    user = await get_collection("users").find_one({"_id": user_oid})
    
    if not user:
        raise HTTPException(status_code=404, detail=f"{field_name.title()} not found")
    
    return user


async def validate_relationship_ownership(
    user_id: str,
    relationship_id: str
) -> Dict[str, Any]:
    """
    Validate that a user owns a family relationship.
    
    Args:
        user_id: String representation of user ID
        relationship_id: String representation of relationship ID
        
    Returns:
        Relationship document
        
    Raises:
        HTTPException: If validation fails
    """
    try:
        user_oid = ObjectId(user_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid user ID")
    
    try:
        rel_oid = ObjectId(relationship_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid relationship ID")
    
    relationship = await get_collection("family_relationships").find_one({
        "_id": rel_oid,
        "user_id": user_oid
    })
    
    if not relationship:
        raise HTTPException(
            status_code=404,
            detail="Relationship not found or you don't have permission to access it"
        )
    
    return relationship


async def validate_invitation_token(token: str) -> Dict[str, Any]:
    """
    Validate an invitation token and check if it's still valid.
    
    Args:
        token: Invitation token string
        
    Returns:
        Invitation document
        
    Raises:
        HTTPException: If token is invalid or expired
    """
    from datetime import datetime
    
    invitation = await get_collection("family_invitations").find_one({"token": token})
    
    if not invitation:
        raise HTTPException(status_code=404, detail="Invitation not found")
    
    if invitation["status"] != "pending":
        raise HTTPException(
            status_code=400,
            detail=f"Invitation has already been {invitation['status']}"
        )
    
    if invitation["expires_at"] < datetime.utcnow():
        await get_collection("family_invitations").update_one(
            {"_id": invitation["_id"]},
            {"$set": {"status": "expired"}}
        )
        raise HTTPException(status_code=410, detail="Invitation has expired")
    
    return invitation


async def validate_invitation_for_user(
    invitation: Dict[str, Any],
    user_email: str
) -> None:
    """
    Validate that an invitation is for the specified user.
    
    Args:
        invitation: Invitation document
        user_email: Email address of the user
        
    Raises:
        HTTPException: If invitation is not for this user
    """
    if invitation["invitee_email"] != user_email.lower():
        raise HTTPException(
            status_code=403,
            detail="This invitation is not for you"
        )


async def validate_circle_ownership_for_invitations(
    user_id: str,
    circle_ids: List[str]
) -> List[Dict[str, Any]]:
    """
    Validate that a user owns all specified circles (for creating invitations).
    
    Args:
        user_id: String representation of user ID
        circle_ids: List of circle IDs
        
    Returns:
        List of circle documents
        
    Raises:
        HTTPException: If user doesn't own all circles
    """
    try:
        user_oid = ObjectId(user_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid user ID")
    
    circle_oids = validate_object_id_list(circle_ids, "circle_ids")
    
    circles = []
    for circle_oid in circle_oids:
        circle = await get_collection("family_circles").find_one({"_id": circle_oid})
        
        if not circle:
            raise HTTPException(
                status_code=404,
                detail=f"Circle with ID {str(circle_oid)} not found"
            )
        
        if circle.get("owner_id") != user_oid:
            raise HTTPException(
                status_code=403,
                detail=f"You do not own circle: {circle.get('name', 'Unknown')}"
            )
        
        circles.append(circle)
    
    return circles


async def validate_no_duplicate_relationship(
    user_id: str,
    related_user_id: str
) -> None:
    """
    Validate that a relationship doesn't already exist.
    
    Args:
        user_id: String representation of user ID
        related_user_id: String representation of related user ID
        
    Raises:
        HTTPException: If relationship already exists
    """
    try:
        user_oid = ObjectId(user_id)
        related_oid = ObjectId(related_user_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid user ID")
    
    existing = await get_collection("family_relationships").find_one({
        "user_id": user_oid,
        "related_user_id": related_oid
    })
    
    if existing:
        raise HTTPException(
            status_code=400,
            detail="A relationship with this user already exists"
        )


async def validate_user_not_owner(circle: Dict[str, Any], user_id: str) -> None:
    """
    Validate that a user is not the owner of a circle (for removal operations).
    
    Args:
        circle: Circle document
        user_id: String representation of user ID to check
        
    Raises:
        HTTPException: If user is the owner
    """
    try:
        user_oid = ObjectId(user_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid user ID")
    
    if circle.get("owner_id") == user_oid:
        raise HTTPException(
            status_code=400,
            detail="Cannot remove the circle owner"
        )


async def validate_user_not_in_circle(circle: Dict[str, Any], user_id: str) -> None:
    """
    Validate that a user is not already in a circle (for add operations).
    
    Args:
        circle: Circle document
        user_id: String representation of user ID to check
        
    Raises:
        HTTPException: If user is already a member
    """
    try:
        user_oid = ObjectId(user_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid user ID")
    
    if user_oid in circle.get("member_ids", []):
        raise HTTPException(
            status_code=400,
            detail="User is already a member of this circle"
        )


async def validate_parent_child_relationship(
    parent_id: str,
    child_id: str,
    ip_address: Optional[str] = None
) -> bool:
    """
    Verify that parent_id has a legitimate parent-child relationship with child_id.
    
    This is a critical security function that prevents unauthorized users from
    creating or modifying parental controls for users they don't have authority over.
    
    Args:
        parent_id: String representation of the parent user ID
        child_id: String representation of the child user ID
        ip_address: Optional IP address for security audit logging
        
    Returns:
        True if a valid parent-child relationship exists
        
    Raises:
        HTTPException: 400 if IDs are invalid, 403 if no valid relationship exists
    """
    try:
        parent_oid = ObjectId(parent_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid parent user ID")
    
    try:
        child_oid = ObjectId(child_id)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid child user ID")
    
    if parent_id == child_id:
        await log_audit_event(
            user_id=parent_id,
            event_type="parental_control_security_violation",
            event_details={
                "violation_type": "self_parental_control",
                "attempted_child_id": child_id,
                "error": "Cannot create parental controls for yourself"
            },
            ip_address=ip_address
        )
        raise HTTPException(
            status_code=403,
            detail="Cannot create parental controls for yourself"
        )
    
    relationships_collection = get_collection("family_relationships")
    
    parent_perspective = await relationships_collection.find_one({
        "user_id": parent_oid,
        "related_user_id": child_oid,
        "relation_type": "child"
    })
    
    child_perspective = await relationships_collection.find_one({
        "user_id": child_oid,
        "related_user_id": parent_oid,
        "relation_type": "parent"
    })
    
    if not parent_perspective and not child_perspective:
        await log_audit_event(
            user_id=parent_id,
            event_type="parental_control_security_violation",
            event_details={
                "violation_type": "unauthorized_parental_control_attempt",
                "attempted_child_id": child_id,
                "error": "No valid parent-child relationship exists"
            },
            ip_address=ip_address
        )
        raise HTTPException(
            status_code=403,
            detail="You do not have a parent-child relationship with this user. Please establish a family relationship first."
        )
    
    await log_audit_event(
        user_id=parent_id,
        event_type="parental_control_validation_success",
        event_details={
            "child_id": child_id,
            "relationship_verified": True
        },
        ip_address=ip_address
    )
    
    return True
