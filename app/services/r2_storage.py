import boto3
import os
from botocore.client import Config
from botocore.exceptions import ClientError
from typing import Optional, BinaryIO
import mimetypes
from datetime import datetime, timedelta

class R2StorageService:
    """Cloudflare R2 Storage Service for file uploads/downloads"""
    
    def __init__(self):
        self.access_key_id = os.getenv('R2_ACCESS_KEY_ID')
        self.secret_access_key = os.getenv('R2_SECRET_ACCESS_KEY')
        self.endpoint_url = os.getenv('R2_ENDPOINT_URL')
        self.bucket_name = os.getenv('R2_BUCKET_NAME')
        
        if not all([self.access_key_id, self.secret_access_key, self.endpoint_url, self.bucket_name]):
            raise ValueError("R2 credentials not properly configured. Please set R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, R2_ENDPOINT_URL, and R2_BUCKET_NAME environment variables.")
        
        self.s3_client = boto3.client(
            's3',
            endpoint_url=self.endpoint_url,
            aws_access_key_id=self.access_key_id,
            aws_secret_access_key=self.secret_access_key,
            config=Config(signature_version='s3v4'),
            region_name='auto'
        )
    
    def upload_file(
        self,
        file_content: BinaryIO,
        file_path: str,
        content_type: Optional[str] = None,
        metadata: Optional[dict] = None
    ) -> dict:
        """
        Upload a file to R2 storage
        
        Args:
            file_content: File-like object containing the file data
            file_path: Path where the file should be stored in R2 (e.g., 'health_records/user123/file.pdf')
            content_type: MIME type of the file (auto-detected if not provided)
            metadata: Optional metadata dictionary to attach to the file
            
        Returns:
            dict: Upload result containing 'success', 'file_url', 'file_path', and 'file_size'
        """
        try:
            if not content_type:
                content_type, _ = mimetypes.guess_type(file_path)
                if not content_type:
                    content_type = 'application/octet-stream'
            
            extra_args = {
                'ContentType': content_type,
            }
            
            if metadata:
                extra_args['Metadata'] = {k: str(v) for k, v in metadata.items()}
            
            file_content.seek(0, 2)
            file_size = file_content.tell()
            file_content.seek(0)
            
            self.s3_client.upload_fileobj(
                file_content,
                self.bucket_name,
                file_path,
                ExtraArgs=extra_args
            )
            
            file_url = f"{self.endpoint_url.rstrip('/')}/{self.bucket_name}/{file_path}"
            
            return {
                'success': True,
                'file_url': file_url,
                'file_path': file_path,
                'file_size': file_size,
                'content_type': content_type
            }
            
        except ClientError as e:
            error_code = e.response.get('Error', {}).get('Code', 'Unknown')
            error_message = e.response.get('Error', {}).get('Message', str(e))
            return {
                'success': False,
                'error': f"R2 Upload Error ({error_code}): {error_message}"
            }
        except Exception as e:
            return {
                'success': False,
                'error': f"Upload failed: {str(e)}"
            }
    
    def download_file(self, file_path: str) -> Optional[bytes]:
        """
        Download a file from R2 storage
        
        Args:
            file_path: Path to the file in R2
            
        Returns:
            bytes: File content if successful, None otherwise
        """
        try:
            response = self.s3_client.get_object(
                Bucket=self.bucket_name,
                Key=file_path
            )
            return response['Body'].read()
        except ClientError as e:
            print(f"Error downloading file from R2: {e}")
            return None
    
    def delete_file(self, file_path: str) -> bool:
        """
        Delete a file from R2 storage
        
        Args:
            file_path: Path to the file in R2
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            self.s3_client.delete_object(
                Bucket=self.bucket_name,
                Key=file_path
            )
            return True
        except ClientError as e:
            print(f"Error deleting file from R2: {e}")
            return False
    
    def generate_presigned_url(
        self,
        file_path: str,
        expiration: int = 3600,
        operation: str = 'get_object'
    ) -> Optional[str]:
        """
        Generate a pre-signed URL for file access
        
        Args:
            file_path: Path to the file in R2
            expiration: Time in seconds until the URL expires (default: 1 hour)
            operation: S3 operation ('get_object' for download, 'put_object' for upload)
            
        Returns:
            str: Pre-signed URL if successful, None otherwise
        """
        try:
            url = self.s3_client.generate_presigned_url(
                operation,
                Params={
                    'Bucket': self.bucket_name,
                    'Key': file_path
                },
                ExpiresIn=expiration
            )
            return url
        except ClientError as e:
            print(f"Error generating presigned URL: {e}")
            return None
    
    def list_files(self, prefix: str = '') -> list:
        """
        List files in R2 storage with optional prefix filter
        
        Args:
            prefix: Prefix to filter files (e.g., 'health_records/user123/')
            
        Returns:
            list: List of file metadata dictionaries
        """
        try:
            response = self.s3_client.list_objects_v2(
                Bucket=self.bucket_name,
                Prefix=prefix
            )
            
            files = []
            for obj in response.get('Contents', []):
                files.append({
                    'file_path': obj['Key'],
                    'size': obj['Size'],
                    'last_modified': obj['LastModified'].isoformat(),
                    'etag': obj['ETag'].strip('"')
                })
            
            return files
        except ClientError as e:
            print(f"Error listing files from R2: {e}")
            return []
    
    def file_exists(self, file_path: str) -> bool:
        """
        Check if a file exists in R2 storage
        
        Args:
            file_path: Path to the file in R2
            
        Returns:
            bool: True if file exists, False otherwise
        """
        try:
            self.s3_client.head_object(
                Bucket=self.bucket_name,
                Key=file_path
            )
            return True
        except ClientError:
            return False
    
    def get_file_metadata(self, file_path: str) -> Optional[dict]:
        """
        Get metadata for a file in R2 storage
        
        Args:
            file_path: Path to the file in R2
            
        Returns:
            dict: File metadata if successful, None otherwise
        """
        try:
            response = self.s3_client.head_object(
                Bucket=self.bucket_name,
                Key=file_path
            )
            return {
                'content_type': response.get('ContentType'),
                'content_length': response.get('ContentLength'),
                'last_modified': response.get('LastModified').isoformat() if response.get('LastModified') else None,
                'etag': response.get('ETag', '').strip('"'),
                'metadata': response.get('Metadata', {})
            }
        except ClientError as e:
            print(f"Error getting file metadata from R2: {e}")
            return None


_r2_storage_instance = None

def get_r2_storage() -> R2StorageService:
    """
    Get or create R2 storage service instance (lazy initialization)
    
    Returns:
        R2StorageService: R2 storage service instance
        
    Raises:
        ValueError: If R2 credentials are not properly configured
    """
    global _r2_storage_instance
    if _r2_storage_instance is None:
        _r2_storage_instance = R2StorageService()
    return _r2_storage_instance
