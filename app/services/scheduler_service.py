import logging
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.interval import IntervalTrigger
from datetime import datetime, timedelta
from app.db.mongodb import get_collection
from app.services.notification_service import NotificationService
from app.models.family.health_records import ReminderStatus, RepeatFrequency

logger = logging.getLogger(__name__)

class SchedulerService:
    _instance = None
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(SchedulerService, cls).__new__(cls)
            cls._instance.scheduler = AsyncIOScheduler()
            cls._instance.notification_service = NotificationService()
        return cls._instance

    def start(self):
        """Start the scheduler"""
        if not self.scheduler.running:
            self.scheduler.add_job(
                self.check_due_reminders,
                trigger=IntervalTrigger(minutes=1),
                id="check_health_reminders",
                replace_existing=True
            )
            self.scheduler.start()
            logger.info("Scheduler service started")

    def shutdown(self):
        """Shutdown the scheduler"""
        if self.scheduler.running:
            self.scheduler.shutdown()
            logger.info("Scheduler service stopped")

    async def check_due_reminders(self):
        """Check for due reminders and send notifications"""
        try:
            now = datetime.utcnow()
            reminders_collection = get_collection("health_record_reminders")
            
            # Find due reminders that are pending
            due_reminders = await reminders_collection.find({
                "due_at": {"$lte": now},
                "status": ReminderStatus.PENDING.value
            }).to_list(length=100)
            
            for reminder in due_reminders:
                await self._process_reminder(reminder)
                
        except Exception as e:
            logger.error(f"Error in check_due_reminders: {str(e)}")

    async def _process_reminder(self, reminder: dict):
        """Process a single reminder"""
        try:
            # Send notification
            await self.notification_service.create_notification(
                user_id=str(reminder["assigned_user_id"]),
                type="health_reminder",
                title=f"Reminder: {reminder['title']}",
                message=reminder.get("description", f"It's time for your {reminder['reminder_type']}"),
                actor_id="system",
                target_type="health_record",
                target_id=str(reminder["record_id"]),
                metadata={
                    "reminder_id": str(reminder["_id"]),
                    "record_id": str(reminder["record_id"]),
                    "reminder_type": reminder["reminder_type"]
                },
                has_reminder=True,
                reminder_due_at=reminder["due_at"]
            )
            
            # Update status
            reminders_collection = get_collection("health_record_reminders")
            
            # Handle recurring reminders
            if reminder.get("repeat_frequency") and reminder["repeat_frequency"] != RepeatFrequency.ONCE.value:
                await self._reschedule_reminder(reminder)
            
            # Mark current as sent
            await reminders_collection.update_one(
                {"_id": reminder["_id"]},
                {"$set": {
                    "status": ReminderStatus.SENT.value,
                    "updated_at": datetime.utcnow()
                }}
            )
            
        except Exception as e:
            logger.error(f"Error processing reminder {reminder.get('_id')}: {str(e)}")

    async def _reschedule_reminder(self, reminder: dict):
        """Create next occurrence for recurring reminder"""
        try:
            current_due = reminder["due_at"]
            frequency = reminder["repeat_frequency"]
            next_due = None
            
            if frequency == RepeatFrequency.DAILY.value:
                next_due = current_due + timedelta(days=1)
            elif frequency == RepeatFrequency.WEEKLY.value:
                next_due = current_due + timedelta(weeks=1)
            elif frequency == RepeatFrequency.MONTHLY.value:
                # Simple monthly addition (approximate)
                next_due = current_due + timedelta(days=30)
            elif frequency == RepeatFrequency.YEARLY.value:
                next_due = current_due.replace(year=current_due.year + 1)
            elif frequency == RepeatFrequency.CUSTOM.value:
                days = reminder.get("repeat_interval_days", 1)
                next_due = current_due + timedelta(days=days)
                
            if next_due:
                # Check repeat count if applicable
                repeat_count = reminder.get("repeat_count")
                if repeat_count is not None:
                    if repeat_count <= 1:
                        return # Stop repeating
                    
                new_reminder = reminder.copy()
                del new_reminder["_id"]
                new_reminder["due_at"] = next_due
                new_reminder["status"] = ReminderStatus.PENDING.value
                new_reminder["created_at"] = datetime.utcnow()
                new_reminder["updated_at"] = datetime.utcnow()
                if repeat_count:
                    new_reminder["repeat_count"] = repeat_count - 1
                    
                await get_collection("health_record_reminders").insert_one(new_reminder)
                
        except Exception as e:
            logger.error(f"Error rescheduling reminder {reminder.get('_id')}: {str(e)}")
