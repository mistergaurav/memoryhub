from typing import Any, Optional, List, Dict, Generic, TypeVar
from pydantic import BaseModel, Field
from datetime import datetime

T = TypeVar('T')


class StandardResponse(BaseModel, Generic[T]):
    """
    Standard response envelope for API endpoints.
    Provides consistent response format across all endpoints.
    """
    success: bool = Field(default=True, description="Indicates if the operation was successful")
    message: str = Field(description="Human-readable message about the operation")
    data: Optional[T] = Field(default=None, description="Response payload data")
    timestamp: datetime = Field(default_factory=datetime.utcnow, description="Response timestamp")
    
    class Config:
        json_schema_extra = {
            "example": {
                "success": True,
                "message": "Operation completed successfully",
                "data": {"id": "123", "name": "Example"},
                "timestamp": "2025-10-22T12:00:00Z"
            }
        }


class PaginatedResponse(BaseModel, Generic[T]):
    """
    Paginated response envelope for list endpoints.
    Provides consistent pagination format.
    """
    success: bool = Field(default=True, description="Indicates if the operation was successful")
    message: str = Field(default="Data retrieved successfully", description="Human-readable message")
    items: List[T] = Field(description="List of items in the current page")
    total: int = Field(description="Total number of items across all pages")
    page: int = Field(description="Current page number (1-indexed)")
    page_size: int = Field(description="Number of items per page")
    total_pages: int = Field(description="Total number of pages")
    has_next: bool = Field(description="Whether there are more pages")
    has_prev: bool = Field(description="Whether there are previous pages")
    timestamp: datetime = Field(default_factory=datetime.utcnow, description="Response timestamp")
    
    class Config:
        json_schema_extra = {
            "example": {
                "success": True,
                "message": "Data retrieved successfully",
                "items": [{"id": "1", "name": "Item 1"}, {"id": "2", "name": "Item 2"}],
                "total": 100,
                "page": 1,
                "page_size": 10,
                "total_pages": 10,
                "has_next": True,
                "has_prev": False,
                "timestamp": "2025-10-22T12:00:00Z"
            }
        }


class ErrorDetail(BaseModel):
    """Detailed error information."""
    field: Optional[str] = Field(default=None, description="Field that caused the error")
    message: str = Field(description="Error message")
    code: Optional[str] = Field(default=None, description="Error code")


class ErrorResponse(BaseModel):
    """
    Error response envelope for API endpoints.
    Provides consistent error format.
    """
    success: bool = Field(default=False, description="Always False for errors")
    error_code: str = Field(description="Machine-readable error code")
    message: str = Field(description="Human-readable error message")
    details: Optional[List[ErrorDetail]] = Field(default=None, description="Detailed error information")
    timestamp: datetime = Field(default_factory=datetime.utcnow, description="Error timestamp")
    
    class Config:
        json_schema_extra = {
            "example": {
                "success": False,
                "error_code": "VALIDATION_ERROR",
                "message": "Invalid input data",
                "details": [
                    {"field": "email", "message": "Invalid email format", "code": "INVALID_FORMAT"}
                ],
                "timestamp": "2025-10-22T12:00:00Z"
            }
        }


def create_success_response(
    message: str = "Operation completed successfully",
    data: Any = None
) -> Dict[str, Any]:
    """
    Create a standard success response.
    
    Args:
        message: Success message
        data: Response data
        
    Returns:
        Success response dictionary
    """
    return StandardResponse(
        success=True,
        message=message,
        data=data
    ).model_dump()


def create_error_response(
    error_code: str,
    message: str,
    details: Optional[List[Dict[str, str]]] = None
) -> Dict[str, Any]:
    """
    Create a standard error response.
    
    Args:
        error_code: Machine-readable error code
        message: Human-readable error message
        details: Optional list of error details
        
    Returns:
        Error response dictionary
    """
    error_details = None
    if details:
        error_details = [ErrorDetail(**d) for d in details]
    
    return ErrorResponse(
        success=False,
        error_code=error_code,
        message=message,
        details=error_details
    ).model_dump()


def create_paginated_response(
    items: List[Any],
    total: int,
    page: int,
    page_size: int,
    message: str = "Data retrieved successfully"
) -> Dict[str, Any]:
    """
    Create a paginated response.
    
    Args:
        items: List of items for current page
        total: Total number of items
        page: Current page number (1-indexed)
        page_size: Number of items per page
        message: Success message
        
    Returns:
        Paginated response dictionary
    """
    total_pages = (total + page_size - 1) // page_size if page_size > 0 else 0
    
    return PaginatedResponse(
        success=True,
        message=message,
        items=items,
        total=total,
        page=page,
        page_size=page_size,
        total_pages=total_pages,
        has_next=page < total_pages,
        has_prev=page > 1
    ).model_dump()


class MessageResponse(BaseModel):
    """Simple message response for operations that don't return data."""
    message: str = Field(description="Operation result message")
    success: bool = Field(default=True, description="Operation success status")
    
    class Config:
        json_schema_extra = {
            "example": {
                "message": "Member added successfully",
                "success": True
            }
        }


def create_message_response(message: str, success: bool = True) -> Dict[str, Any]:
    """
    Create a simple message response.
    
    Args:
        message: Response message
        success: Success status
        
    Returns:
        Message response dictionary
    """
    return MessageResponse(message=message, success=success).model_dump()
