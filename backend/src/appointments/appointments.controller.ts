import { Controller, Get, Post, Delete, Patch, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { AppointmentsService } from './appointments.service';
import { CreateAppointmentDto } from './dto/create-appointment.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('appointments')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('appointments')
export class AppointmentsController {
  constructor(private service: AppointmentsService) {}

  @Get()
  @ApiOperation({ summary: 'GET /appointments — всі прийоми' })
  findAll() {
    return this.service.findAll();
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
}
