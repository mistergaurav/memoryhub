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
    """Check if user has access to the tree with optional role requirements"""
    
    if tree_id == user_id:
        tree = await tree_repo.find_by_id(str(tree_id), raise_404=False)
        if not tree:
            return None, "owner"
        return tree, "owner"
    
    tree = await tree_repo.find_by_id(str(tree_id), raise_404=False)
    if not tree:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Tree not found")
    
    if tree.get("created_by") == user_id:
        return tree, "owner"
    
    membership = await tree_membership_repo.find_one({"tree_id": tree_id, "user_id": user_id}, raise_404=False)
    if not membership:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")
    
    user_role = membership.get("role", "viewer")
    if required_roles and user_role not in required_roles:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Insufficient permissions. Required: {required_roles}"
        )
    
    return tree, user_role


