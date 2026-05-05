import { Injectable } from '@nestjs/common';
import { PatientsService } from '../patients/patients.service';
import { AppointmentsService } from '../appointments/appointments.service';

@Injectable()
export class DashboardService {
  constructor(
    private patientsService: PatientsService,
    private appointmentsService: AppointmentsService,
  ) {}

  async getStats() {
    const [todayCount, patientCount, todayAppointments] = await Promise.all([
      this.appointmentsService.countToday(),
      this.patientsService.count(),
      this.appointmentsService.findToday(),
    ]);
    return {
      appointmentsToday: todayCount,
      newPatientsToday: 3,
      activePatients: patientCount,
      occupancyPercent: 98,
      upcomingAppointments: todayAppointments.slice(0, 5),
    };
  }
}
