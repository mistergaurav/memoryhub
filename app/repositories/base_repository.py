from typing import Optional, List, Dict, Any, TypeVar, Generic
from bson import ObjectId
from datetime import datetime
from fastapi import HTTPException
from app.db.mongodb import get_collection

T = TypeVar('T')


class BaseRepository(Generic[T]):
    """
    Generic base repository providing common CRUD operations for MongoDB collections.
    Eliminates code duplication and provides consistent data access patterns.
    """
    
    def __init__(self, collection_name: str):
        """
        Initialize repository with collection name.
        
        Args:
            collection_name: Name of the MongoDB collection
        """
        self.collection_name = collection_name
        self._collection = None
    
    @property
    def collection(self):
        """Get the MongoDB collection instance."""
        if self._collection is None:
            self._collection = get_collection(self.collection_name)
        return self._collection
    
    def validate_object_id(self, id_str: str, field_name: str = "ID") -> ObjectId:
        """
        Validate and convert string to ObjectId.
        
        Args:
            id_str: String representation of ObjectId
            field_name: Name of field for error message
            
        Returns:
            Valid ObjectId
            
        Raises:
            HTTPException: If ID is invalid
        """
        try:
            return ObjectId(id_str)
        except Exception:
            raise HTTPException(status_code=400, detail=f"Invalid {field_name}: {id_str}")
    
    def validate_object_ids(self, id_list: List[str], field_name: str = "IDs") -> List[ObjectId]:
        """
        Validate and convert list of strings to ObjectIds.
        
        Args:
            id_list: List of string representations
            field_name: Name of field for error message
            
        Returns:
            List of valid ObjectIds
            
        Raises:
            HTTPException: If any ID is invalid
        """
        result = []
        for id_str in id_list:
            result.append(self.validate_object_id(id_str, field_name))
        return result
    
    async def find_one(
        self,
        filter_dict: Dict[str, Any],
        raise_404: bool = True,
        error_message: str = "Document not found"
    ) -> Optional[Dict[str, Any]]:
        """
        Find a single document by filter.
        
        Args:
            filter_dict: MongoDB filter criteria
            raise_404: Whether to raise 404 if not found
            error_message: Custom error message
            
        Returns:
            Document if found, None otherwise
            
        Raises:
            HTTPException: If document not found and raise_404=True
        """
        doc = await self.collection.find_one(filter_dict)
        if not doc and raise_404:
            raise HTTPException(status_code=404, detail=error_message)
        return doc
    
    async def find_by_id(
        self,
        doc_id: str,
        raise_404: bool = True,
        error_message: str = "Document not found"
    ) -> Optional[Dict[str, Any]]:
        """
        Find a document by ID.
        
        Args:
            doc_id: String representation of document ID
            raise_404: Whether to raise 404 if not found
            error_message: Custom error message
            
        Returns:
            Document if found, None otherwise
        """
        oid = self.validate_object_id(doc_id, "document ID")
        return await self.find_one({"_id": oid}, raise_404, error_message)
    
    async def find_many(
        self,
        filter_dict: Optional[Dict[str, Any]] = None,
        skip: int = 0,
        limit: int = 50,
        sort_by: Optional[str] = None,
        sort_order: int = -1
    ) -> List[Dict[str, Any]]:
        """
        Find multiple documents with pagination and sorting.
        
        Args:
            filter_dict: MongoDB filter criteria (default: {})
            skip: Number of documents to skip
            limit: Maximum number of documents to return
            sort_by: Field name to sort by
            sort_order: Sort order (1 for ascending, -1 for descending)
            
        Returns:
            List of documents
        """
        if filter_dict is None:
            filter_dict = {}
        
        cursor = self.collection.find(filter_dict).skip(skip).limit(limit)
        
        if sort_by:
            cursor = cursor.sort(sort_by, sort_order)
        
        return await cursor.to_list(length=limit)
    
    async def count(self, filter_dict: Optional[Dict[str, Any]] = None) -> int:
        """
        Count documents matching filter.
        
        Args:
            filter_dict: MongoDB filter criteria (default: {})
            
        Returns:
            Number of matching documents
        """
        if filter_dict is None:
            filter_dict = {}
        return await self.collection.count_documents(filter_dict)
    
    async def create(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Create a new document.
        
        Args:
            data: Document data to insert
            
        Returns:
            Created document with _id
            
        Raises:
            HTTPException: If creation fails
        """
        try:
            if "created_at" not in data:
                data["created_at"] = datetime.utcnow()
            if "updated_at" not in data:
                data["updated_at"] = datetime.utcnow()
            
            result = await self.collection.insert_one(data)
            created_doc = await self.find_one({"_id": result.inserted_id}, raise_404=True)
            assert created_doc is not None
            return created_doc
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Failed to create document: {str(e)}"
            )
    
    async def update(
        self,
        filter_dict: Dict[str, Any],
        update_data: Dict[str, Any],
        raise_404: bool = True
    ) -> Optional[Dict[str, Any]]:
        """
        Update a document.
        
        Args:
            filter_dict: MongoDB filter criteria
            update_data: Data to update
            raise_404: Whether to raise 404 if not found
            
        Returns:
            Updated document
            
        Raises:
            HTTPException: If update fails or document not found
        """
        try:
            update_data["updated_at"] = datetime.utcnow()
            
            result = await self.collection.update_one(
                filter_dict,
                {"$set": update_data}
            )
            
            if result.matched_count == 0 and raise_404:
                raise HTTPException(status_code=404, detail="Document not found")
            
            return await self.find_one(filter_dict, raise_404=False)
        except HTTPException:
            raise
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Failed to update document: {str(e)}"
            )
    
    async def update_by_id(
        self,
        doc_id: str,
        update_data: Dict[str, Any],
        raise_404: bool = True
    ) -> Optional[Dict[str, Any]]:
        """
        Update a document by ID.
        
        Args:
            doc_id: String representation of document ID
            update_data: Data to update
            raise_404: Whether to raise 404 if not found
            
        Returns:
            Updated document
        """
        oid = self.validate_object_id(doc_id, "document ID")
        return await self.update({"_id": oid}, update_data, raise_404)
    
    async def delete(
        self,
        filter_dict: Dict[str, Any],
        raise_404: bool = True
    ) -> bool:
        """
        Delete a document.
        
        Args:
            filter_dict: MongoDB filter criteria
            raise_404: Whether to raise 404 if not found
            
        Returns:
            True if deleted
            
        Raises:
            HTTPException: If deletion fails or document not found
        """
        try:
            result = await self.collection.delete_one(filter_dict)
            
            if result.deleted_count == 0 and raise_404:
                raise HTTPException(status_code=404, detail="Document not found")
            
            return result.deleted_count > 0
        except HTTPException:
            raise
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"Failed to delete document: {str(e)}"
            )
    
    async def delete_by_id(self, doc_id: str, raise_404: bool = True) -> bool:
        """
        Delete a document by ID.
        
        Args:
            doc_id: String representation of document ID
            raise_404: Whether to raise 404 if not found
            
        Returns:
            True if deleted
        """
        oid = self.validate_object_id(doc_id, "document ID")
        return await self.delete({"_id": oid}, raise_404)
    
    async def delete_many(self, filter_dict: Dict[str, Any]) -> int:
        """
        Delete multiple documents.
        
        Args:
            filter_dict: MongoDB filter criteria
            
        Returns:
            Number of documents deleted
        """
        result = await self.collection.delete_many(filter_dict)
        return result.deleted_count
    
    async def exists(self, filter_dict: Dict[str, Any]) -> bool:
        """
        Check if a document exists.
        
        Args:
            filter_dict: MongoDB filter criteria
            
        Returns:
            True if document exists
        """
        doc = await self.collection.find_one(filter_dict, {"_id": 1})
        return doc is not None
    
    async def aggregate(
        self,
        pipeline: List[Dict[str, Any]],
        **kwargs
    ) -> List[Dict[str, Any]]:
        """
        Execute an aggregation pipeline and return results.
        
        Args:
            pipeline: MongoDB aggregation pipeline
            **kwargs: Additional options for aggregation
            
        Returns:
            List of aggregation results
        """
        cursor = self.collection.aggregate(pipeline, **kwargs)
        return await cursor.to_list(length=None)
    
    async def aggregate_paginated(
        self,
        pipeline: List[Dict[str, Any]],
        skip: int = 0,
        limit: int = 20,
        **kwargs
    ) -> Dict[str, Any]:
        """
        Execute an aggregation pipeline with pagination support.
        
        This method runs the pipeline twice:
        1. Once with $count to get total documents
        2. Once with $skip and $limit for paginated results
        
        Args:
            pipeline: MongoDB aggregation pipeline (without $skip/$limit)
            skip: Number of documents to skip
            limit: Maximum number of documents to return
            **kwargs: Additional options for aggregation
            
        Returns:
            PaginatedResponse-compatible dictionary with items and pagination metadata
        """
        count_pipeline = pipeline + [{"$count": "total"}]
        count_result = await self.collection.aggregate(count_pipeline, **kwargs).to_list(length=1)
        total = count_result[0]["total"] if count_result else 0
        
        data_pipeline = pipeline + [
            {"$skip": skip},
            {"$limit": limit}
        ]
        items = await self.collection.aggregate(data_pipeline, **kwargs).to_list(length=limit)
        
        page = (skip // limit) + 1 if limit > 0 else 1
        total_pages = (total + limit - 1) // limit if limit > 0 else 0
        
        from app.models.responses import create_paginated_response
        return create_paginated_response(
            items=items,
            total=total,
            page=page,
            page_size=limit
        )
