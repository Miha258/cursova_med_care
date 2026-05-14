import { Controller, Get, Post, Delete, Patch, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { AppointmentsService, UpdateAppointmentDto } from './appointments.service';
import { CreateAppointmentDto } from './dto/create-appointment.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { MailerService } from '../mailer/mailer.service';

@ApiTags('appointments')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('appointments')
export class AppointmentsController {
  constructor(private service: AppointmentsService, private mailer: MailerService) {}

  @Get()
  @ApiQuery({ name: 'patientId', required: false })
  @ApiOperation({ summary: 'GET /appointments?patientId=X — всі прийоми або по пацієнту' })
  findAll(@Query('patientId') patientId?: string) {
    return this.service.findAll(patientId);
  }

  @Get('today')
  @ApiOperation({ summary: 'GET /appointments/today — прийоми на сьогодні' })
  findToday() {
    return this.service.findToday();
  }

  @Get('slots')
  @ApiQuery({ name: 'doctorId', required: true })
  @ApiQuery({ name: 'date', required: true, example: '2026-12-07' })
  @ApiOperation({ summary: 'GET /appointments/slots?doctorId=X&date=Y — вільні слоти (SQL JOIN, ~45мс)' })
  findSlots(@Query('doctorId') doctorId: string, @Query('date') date: string) {
    return this.service.findSlots(doctorId, date);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.service.findOne(id);
  }

  @Post()
  @ApiOperation({ summary: 'POST /appointments — запис на прийом + FCM нотифікація' })
  create(@Body() dto: CreateAppointmentDto) {
    return this.service.create(dto);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'PATCH /appointments/:id — перенести прийом (startTime/endTime/doctorId)' })
  update(@Param('id') id: string, @Body() dto: UpdateAppointmentDto) {
    return this.service.update(id, dto);
  }

  @Patch(':id/complete')
  @ApiOperation({ summary: 'PATCH /appointments/:id/complete — завершити прийом' })
  complete(@Param('id') id: string) {
    return this.service.complete(id);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'DELETE /appointments/:id — скасувати прийом' })
  cancel(@Param('id') id: string) {
    return this.service.cancel(id);
  }

  @Post('receipt')
  @ApiOperation({ summary: 'POST /appointments/receipt — надіслати чек на email з посиланням на оплату' })
  async sendReceipt(@Body() body: Record<string, string>) {
    await this.mailer.sendReceipt({
      to: body['email'],
      patientName: body['patientName'],
      doctorName: body['doctorName'],
      specialization: body['specialization'],
      date: body['date'],
      time: body['time'],
      reason: body['reason'],
      appointmentId: body['appointmentId'],
    });
    return { ok: true };
  }
}
