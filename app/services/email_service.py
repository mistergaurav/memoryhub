"""
Email Service - Abstraction layer for sending transactional emails
Supports multiple email providers (SendGrid, Resend, SMTP)
"""
from typing import Optional, List, Dict, Any
from datetime import datetime
import os
from abc import ABC, abstractmethod


class EmailProvider(ABC):
    """Abstract base class for email providers"""
    
    @abstractmethod
    async def send_email(
        self,
        to_email: str,
        subject: str,
        html_content: str,
        text_content: Optional[str] = None,
        from_email: Optional[str] = None,
        from_name: Optional[str] = None
    ) -> bool:
        """Send an email"""
        pass


class ResendEmailProvider(EmailProvider):
    """Resend email provider implementation"""
    
    def __init__(self, api_key: str):
        self.api_key = api_key
        self.from_email = os.getenv("FROM_EMAIL", "noreply@memoryhub.app")
        self.from_name = os.getenv("FROM_NAME", "Memory Hub")
    
    async def send_email(
        self,
        to_email: str,
        subject: str,
        html_content: str,
        text_content: Optional[str] = None,
        from_email: Optional[str] = None,
        from_name: Optional[str] = None
    ) -> bool:
        """Send email via Resend API"""
        try:
            import httpx
            
            sender_email = from_email or self.from_email
            sender_name = from_name or self.from_name
            
            payload = {
                "from": f"{sender_name} <{sender_email}>",
                "to": [to_email],
                "subject": subject,
                "html": html_content,
            }
            
            if text_content:
                payload["text"] = text_content
            
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    "https://api.resend.com/emails",
                    headers={
                        "Authorization": f"Bearer {self.api_key}",
                        "Content-Type": "application/json"
                    },
                    json=payload,
                    timeout=30.0
                )
                
                return response.status_code == 200
        except Exception as e:
            print(f"Failed to send email via Resend: {e}")
            return False


class SendGridEmailProvider(EmailProvider):
    """SendGrid email provider implementation"""
    
    def __init__(self, api_key: str):
        self.api_key = api_key
        self.from_email = os.getenv("FROM_EMAIL", "noreply@memoryhub.app")
        self.from_name = os.getenv("FROM_NAME", "Memory Hub")
    
    async def send_email(
        self,
        to_email: str,
        subject: str,
        html_content: str,
        text_content: Optional[str] = None,
        from_email: Optional[str] = None,
        from_name: Optional[str] = None
    ) -> bool:
        """Send email via SendGrid API"""
        try:
            import httpx
            
            sender_email = from_email or self.from_email
            sender_name = from_name or self.from_name
            
            payload = {
                "personalizations": [{
                    "to": [{"email": to_email}]
                }],
                "from": {
                    "email": sender_email,
                    "name": sender_name
                },
                "subject": subject,
                "content": [
                    {
                        "type": "text/html",
                        "value": html_content
                    }
                ]
            }
            
            if text_content:
                payload["content"].insert(0, {
                    "type": "text/plain",
                    "value": text_content
                })
            
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    "https://api.sendgrid.com/v3/mail/send",
                    headers={
                        "Authorization": f"Bearer {self.api_key}",
                        "Content-Type": "application/json"
                    },
                    json=payload,
                    timeout=30.0
                )
                
                return response.status_code == 202
        except Exception as e:
            print(f"Failed to send email via SendGrid: {e}")
            return False


class SMTPEmailProvider(EmailProvider):
    """SMTP email provider implementation (fallback)"""
    
    def __init__(self, host: str, port: int, username: str, password: str):
        self.host = host
        self.port = port
        self.username = username
        self.password = password
        self.from_email = os.getenv("FROM_EMAIL", "noreply@memoryhub.app")
        self.from_name = os.getenv("FROM_NAME", "Memory Hub")
    
    async def send_email(
        self,
        to_email: str,
        subject: str,
        html_content: str,
        text_content: Optional[str] = None,
        from_email: Optional[str] = None,
        from_name: Optional[str] = None
    ) -> bool:
        """Send email via SMTP"""
        try:
            import smtplib
            from email.mime.text import MIMEText
            from email.mime.multipart import MIMEMultipart
            
            sender_email = from_email or self.from_email
            sender_name = from_name or self.from_name
            
            msg = MIMEMultipart('alternative')
            msg['Subject'] = subject
            msg['From'] = f"{sender_name} <{sender_email}>"
            msg['To'] = to_email
            
            if text_content:
                part1 = MIMEText(text_content, 'plain')
                msg.attach(part1)
            
            part2 = MIMEText(html_content, 'html')
            msg.attach(part2)
            
            with smtplib.SMTP(self.host, self.port) as server:
                server.starttls()
                server.login(self.username, self.password)
                server.sendmail(sender_email, to_email, msg.as_string())
            
            return True
        except Exception as e:
            print(f"Failed to send email via SMTP: {e}")
            return False


class EmailService:
    """Main email service with template support"""
    
    def __init__(self):
        self.provider = self._initialize_provider()
        self.app_url = os.getenv("REPLIT_DEV_DOMAIN", "")
        if self.app_url:
            self.app_url = f"https://{self.app_url}"
        else:
            self.app_url = "http://localhost:5000"
    
    def _initialize_provider(self) -> Optional[EmailProvider]:
        """Initialize email provider based on available credentials"""
        # Try Resend first (from Replit integration)
        resend_key = os.getenv("RESEND_API_KEY")
        if resend_key:
            return ResendEmailProvider(resend_key)
        
        # Try SendGrid
        sendgrid_key = os.getenv("SENDGRID_API_KEY")
        if sendgrid_key:
            return SendGridEmailProvider(sendgrid_key)
        
        # Try SMTP as fallback
        smtp_host = os.getenv("SMTP_HOST")
        smtp_port = os.getenv("SMTP_PORT")
        smtp_user = os.getenv("SMTP_USERNAME")
        smtp_pass = os.getenv("SMTP_PASSWORD")
        
        if all([smtp_host, smtp_port, smtp_user, smtp_pass]):
            return SMTPEmailProvider(smtp_host, int(smtp_port), smtp_user, smtp_pass)
        
        return None
    
    def is_configured(self) -> bool:
        """Check if email service is configured"""
        return self.provider is not None
    
    async def send_password_reset_email(self, to_email: str, reset_token: str, user_name: Optional[str] = None) -> bool:
        """Send password reset email"""
        if not self.provider:
            print("Email service not configured - skipping password reset email")
            return False
        
        reset_link = f"{self.app_url}/reset-password?token={reset_token}"
        
        html_content = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                .header {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }}
                .content {{ background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }}
                .button {{ display: inline-block; padding: 12px 30px; background: #667eea; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; }}
                .footer {{ margin-top: 30px; text-align: center; color: #666; font-size: 12px; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>Password Reset Request</h1>
                </div>
                <div class="content">
                    <p>Hello{' ' + user_name if user_name else ''},</p>
                    <p>We received a request to reset your password for your Memory Hub account.</p>
                    <p>Click the button below to reset your password. This link will expire in 1 hour.</p>
                    <p style="text-align: center;">
                        <a href="{reset_link}" class="button">Reset Password</a>
                    </p>
                    <p>Or copy and paste this link into your browser:</p>
                    <p style="word-break: break-all; background: #fff; padding: 10px; border-radius: 5px;">{reset_link}</p>
                    <p>If you didn't request this password reset, you can safely ignore this email.</p>
                </div>
                <div class="footer">
                    <p>This is an automated message from Memory Hub. Please do not reply to this email.</p>
                    <p>&copy; {datetime.now().year} Memory Hub. All rights reserved.</p>
                </div>
            </div>
        </body>
        </html>
        """
        
        text_content = f"""
        Password Reset Request
        
        Hello{' ' + user_name if user_name else ''},
        
        We received a request to reset your password for your Memory Hub account.
        
        Click or copy this link to reset your password (expires in 1 hour):
        {reset_link}
        
        If you didn't request this password reset, you can safely ignore this email.
        
        ---
        This is an automated message from Memory Hub. Please do not reply to this email.
        © {datetime.now().year} Memory Hub. All rights reserved.
        """
        
        return await self.provider.send_email(
            to_email=to_email,
            subject="Reset Your Memory Hub Password",
            html_content=html_content,
            text_content=text_content
        )
    
    async def send_verification_email(self, to_email: str, verification_token: str, user_name: Optional[str] = None) -> bool:
        """Send email verification email"""
        if not self.provider:
            print("Email service not configured - skipping verification email")
            return False
        
        verification_link = f"{self.app_url}/verify-email?token={verification_token}"
        
        html_content = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                .header {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }}
                .content {{ background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }}
                .button {{ display: inline-block; padding: 12px 30px; background: #667eea; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; }}
                .footer {{ margin-top: 30px; text-align: center; color: #666; font-size: 12px; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>Welcome to Memory Hub!</h1>
                </div>
                <div class="content">
                    <p>Hello{' ' + user_name if user_name else ''},</p>
                    <p>Thank you for creating a Memory Hub account! We're excited to help you preserve and share your precious memories.</p>
                    <p>Please verify your email address by clicking the button below:</p>
                    <p style="text-align: center;">
                        <a href="{verification_link}" class="button">Verify Email Address</a>
                    </p>
                    <p>Or copy and paste this link into your browser:</p>
                    <p style="word-break: break-all; background: #fff; padding: 10px; border-radius: 5px;">{verification_link}</p>
                    <p>This link will expire in 24 hours.</p>
                </div>
                <div class="footer">
                    <p>This is an automated message from Memory Hub. Please do not reply to this email.</p>
                    <p>&copy; {datetime.now().year} Memory Hub. All rights reserved.</p>
                </div>
            </div>
        </body>
        </html>
        """
        
        text_content = f"""
        Welcome to Memory Hub!
        
        Hello{' ' + user_name if user_name else ''},
        
        Thank you for creating a Memory Hub account! We're excited to help you preserve and share your precious memories.
        
        Please verify your email address by clicking this link (expires in 24 hours):
        {verification_link}
        
        ---
        This is an automated message from Memory Hub. Please do not reply to this email.
        © {datetime.now().year} Memory Hub. All rights reserved.
        """
        
        return await self.provider.send_email(
            to_email=to_email,
            subject="Verify Your Memory Hub Email Address",
            html_content=html_content,
            text_content=text_content
        )
    
    async def send_welcome_email(self, to_email: str, user_name: str) -> bool:
        """Send welcome email after successful verification"""
        if not self.provider:
            return False
        
        html_content = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                .header {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }}
                .content {{ background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }}
                .feature {{ background: white; padding: 15px; margin: 10px 0; border-radius: 5px; }}
                .button {{ display: inline-block; padding: 12px 30px; background: #667eea; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>🎉 You're All Set!</h1>
                </div>
                <div class="content">
                    <p>Hi {user_name},</p>
                    <p>Your Memory Hub account is now fully activated! Here's what you can do:</p>
                    
                    <div class="feature">
                        <h3>📸 Create Memories</h3>
                        <p>Upload photos, videos, and voice notes to preserve your special moments</p>
                    </div>
                    
                    <div class="feature">
                        <h3>👨‍👩‍👧‍👦 Build Family Connections</h3>
                        <p>Create family circles, collaborate on albums, and share your story</p>
                    </div>
                    
                    <div class="feature">
                        <h3>🔒 Stay Private & Secure</h3>
                        <p>Control who sees what with granular privacy settings</p>
                    </div>
                    
                    <p style="text-align: center;">
                        <a href="{self.app_url}" class="button">Start Creating Memories</a>
                    </p>
                </div>
            </div>
        </body>
        </html>
        """
        
        return await self.provider.send_email(
            to_email=to_email,
            subject="Welcome to Memory Hub! 🎉",
            html_content=html_content
        )


# Global email service instance
_email_service: Optional[EmailService] = None


def get_email_service() -> EmailService:
    """Get or create email service singleton"""
    global _email_service
    if _email_service is None:
        _email_service = EmailService()
    return _email_service
