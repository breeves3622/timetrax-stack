{
    'name': 'Kiosk Attendance Alerts',
    'version': '1.0',
    'category': 'Human Resources',
    'summary': 'Delayed break notifications for employee attendance kiosk',
    'description': """
        Custom module extending hr_attendance for employee kiosk.
        When an employee's status changes to 'On Break', it schedules an automated action (ir.cron)
        to output a delayed log entry 25 minutes later: 'Send break ending SMS to [User]'.
    """,
    'author': 'Antigravity',
    'depends': ['hr_attendance'],
    'data': [],
    'installable': True,
    'application': False,
    'auto_install': False,
    'license': 'LGPL-3',
}
