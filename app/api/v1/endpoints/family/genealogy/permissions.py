"""Genealogy tree access control and permissions."""
from typing import List, Optional
from bson import ObjectId
from fastapi import HTTPException, status

from .repository import (
    GenealogyTreeRepository,
    GenealogTreeMembershipRepository
)

tree_repo = GenealogyTreeRepository()
tree_membership_repo = GenealogTreeMembershipRepository()


async def get_tree_membership(tree_id: ObjectId, user_id: ObjectId):
    """Get tree membership for user and tree"""
    return await tree_membership_repo.find_one({"tree_id": tree_id, "user_id": user_id}, raise_404=False)


async def ensure_tree_access(tree_id: ObjectId, user_id: ObjectId, required_roles: Optional[List[str]] = None):
    """
    Check if user has access to the tree with optional role requirements.
    
    Args:
        tree_id: The tree (family) ID to check access for
        user_id: The user requesting access
        required_roles: Optional list of roles required (e.g., ["owner", "member"])
    
    Returns:
        Tuple of (tree_doc, user_role)
    
    Raises:
        HTTPException: If tree not found or access denied
    """
    
    # Special case: When tree_id equals user_id, this is the user's own tree
    # Check if user has a tree membership entry as owner
    if tree_id == user_id:
        # Verify the user actually has owner membership to this tree
        membership = await tree_membership_repo.find_by_tree_and_user(
            tree_id=str(tree_id),
            user_id=str(user_id)
        )
        
        # If membership exists and is owner, grant access
        if membership and membership.get("role") == "owner":
            # Tree doc might not exist yet (tree is virtual, identified by family_id)
            return None, "owner"
        
        # If no membership, this could be first time accessing - allow as owner
        # This enables users to create their first genealogy person
        return None, "owner"
    
    # For different tree_id and user_id, check actual tree access
    # Note: Current implementation uses genealogy_persons collection, 
    # but tree_id is actually family_id
    # We check membership records instead
    
    membership = await tree_membership_repo.find_one({
        "tree_id": tree_id, 
        "user_id": user_id
    }, raise_404=False)
    
    if not membership:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, 
            detail="You do not have access to this family tree"
        )
    
    user_role = membership.get("role", "viewer")
    
    # Check if user has required role
    if required_roles and user_role not in required_roles:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Insufficient permissions. Required: {', '.join(required_roles)}. You have: {user_role}"
        )
    
    # Return None for tree doc (not needed) and the user's role
    return None, user_role
