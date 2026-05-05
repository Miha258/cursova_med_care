import { Controller, Get, Post, Patch, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { MedicalRecordsService, CreateMedicalRecordDto } from './medical-records.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('medical-records')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('medical-records')
export class MedicalRecordsController {
  constructor(private service: MedicalRecordsService) {}

  @Get()
  @ApiOperation({ summary: 'GET /medical-records?patientId=X — записи пацієнта' })
  findByPatient(@Query('patientId') patientId: string) {
    return this.service.findByPatient(patientId);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.service.findOne(id);
  }

  @Post()
  @ApiOperation({ summary: 'POST /medical-records — створити ЕМК' })
  create(@Body() dto: CreateMedicalRecordDto) {
    return this.service.create(dto);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'PATCH /medical-records/:id — оновлення ЕМК + audit log' })
  update(@Param('id') id: string, @Body() dto: Partial<CreateMedicalRecordDto>) {
    return this.service.update(id, dto);
  }
}
