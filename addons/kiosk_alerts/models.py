import logging
from datetime import timedelta
from odoo import models, fields, api

_logger = logging.getLogger(__name__)

class HrAttendance(models.Model):
    _inherit = 'hr.attendance'

    @api.model_create_multi
    def create(self, vals_list):
        records = super(HrAttendance, self).create(vals_list)
        for record in records:
            record._check_and_schedule_break_alert()
        return records

    def write(self, vals):
        res = super(HrAttendance, self).write(vals)
        for record in self:
            record._check_and_schedule_break_alert()
        return res

    def _check_and_schedule_break_alert(self):
        """
        Checks if employee or attendance record is in 'On Break' status.
        Schedules an automated ir.cron action 25 minutes in the future.
        """
        for attendance in self:
            employee = attendance.employee_id
            if not employee:
                continue

            # Determine if status matches 'On Break'
            is_on_break = False
            if hasattr(employee, 'attendance_state') and employee.attendance_state in ['on_break', 'break']:
                is_on_break = True
            elif hasattr(attendance, 'attendance_state') and attendance.attendance_state in ['on_break', 'break']:
                is_on_break = True
            elif hasattr(attendance, 'x_status') and attendance.x_status == 'On Break':
                is_on_break = True

            if is_on_break:
                attendance._schedule_break_ending_sms_cron(employee)

    def _schedule_break_ending_sms_cron(self, employee):
        """
        Schedules a one-shot ir.cron automated action set for 25 minutes later.
        """
        run_time = fields.Datetime.now() + timedelta(minutes=25)
        user_name = employee.name or (employee.user_id.name if employee.user_id else "Employee")
        cron_name = f"Break Ending SMS Alert for {user_name} (Emp ID: {employee.id})"

        self.env['ir.cron'].sudo().create({
            'name': cron_name,
            'model_id': self.env['ir.model']._get('hr.attendance').id,
            'state': 'code',
            'code': f"model._log_break_ending_sms({employee.id}, {repr(user_name)})",
            'interval_number': 1,
            'interval_type': 'minutes',
            'numbercall': 1,
            'nextcall': run_time,
            'active': True,
        })
        _logger.info("Scheduled break ending SMS cron for %s at %s", user_name, run_time)

    @api.model
    def _log_break_ending_sms(self, employee_id, user_name):
        """
        Executed by Odoo internal cron 25 minutes post break-start.
        Outputs delayed log entry: 'Send break ending SMS to [User]'
        """
        _logger.info("Send break ending SMS to %s", user_name)
