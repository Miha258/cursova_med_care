import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { ReportsService } from './reports.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('reports')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('reports')
export class ReportsController {
  constructor(private service: ReportsService) {}

  @Get('appointments')
  @ApiOperation({ summary: 'GET /reports/appointments — звіт прийомів (PostgreSQL CTE-запит)' })
  appointments(@Query('from') from?: string, @Query('to') to?: string) {
    return this.service.getAppointmentReport(from, to);
  }

  @Get('revenue')
  @ApiOperation({ summary: 'GET /reports/revenue — фінансовий звіт по місяцях (PostgreSQL агрегація)' })
  revenue(@Query('from') from?: string, @Query('to') to?: string) {
    return this.service.getRevenueReport(from, to);
  }

  @Get('doctors')
  @ApiOperation({ summary: 'GET /reports/doctors — завантаженість лікарів' })
  doctors() {
    return this.service.getDoctorWorkload();
  }
}
