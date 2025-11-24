from typing import List, Dict, Any
from datetime import datetime
from bson import ObjectId
from app.core.config import settings

async def process_memory_search_filters(
    search_params: Dict[str, Any], 
    current_user_id: str
) -> Dict[str, Any]:
    filters = {}
    
    # Privacy filter
    if search_params.get('privacy'):
        filters['privacy'] = search_params['privacy']
    else:
        filters['$or'] = [
            {'owner_id': ObjectId(current_user_id)},
            {'privacy': 'public'},
            {
                'privacy': 'friends',
                'owner_id': {'$in': []}  # Will be populated with friend IDs
            }
        ]
    
    # Text search
    if search_params.get('query'):
        filters['$text'] = {'$search': search_params['query']}
    
    # Tags filter
    if search_params.get('tags'):
        filters['tags'] = {'$all': search_params['tags']}
    
    # Date range filter
    date_filter = {}
    if search_params.get('start_date'):
        date_filter['$gte'] = search_params['start_date']
    if search_params.get('end_date'):
        date_filter['$lte'] = search_params['end_date']
    if date_filter:
        filters['created_at'] = date_filter
        
    # Person filter - supports both platform users and genealogy persons
    if search_params.get('person_id'):
        person_id = search_params['person_id']
        # Search in both tagged_family_members (platform users) and genealogy_person_ids
        filters['$or'] = [
            {'tagged_family_members.user_id': person_id},
            {'genealogy_person_ids': person_id}
        ]
    
    return filters

def get_sort_params(sort_by: str, sort_order: str) -> list:
    sort_field = {
        "created_at": "created_at",
        "updated_at": "updated_at",
        "title": "title",
        "views": "view_count",
        "likes": "like_count"
    }.get(sort_by, "created_at")
    
    sort_direction = -1 if sort_order.lower() == "desc" else 1
    return [(sort_field, sort_direction)]

async def increment_memory_counter(memory_id: str, field: str, value: int = 1):
    from app.db.mongodb import get_collection
    await get_collection("memories").update_one(
        {"_id": ObjectId(memory_id)},
        {"$inc": {field: value}}
    )