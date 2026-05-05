import { Controller, Get, Post, Patch, Delete, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { PharmacyService } from './pharmacy.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { Medication } from './entities/medication.entity';
import { Prescription } from './entities/prescription.entity';

@ApiTags('pharmacy')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('medications')
export class PharmacyController {
  constructor(private service: PharmacyService) {}

  @Get()
  @ApiOperation({ summary: 'GET /medications — список медикаментів з контролем залишків' })
  findAll() {
    return this.service.findAllMedications();
  }

  @Get('low-stock')
  @ApiOperation({ summary: 'GET /medications/low-stock — автоматичне попередження про мінімальний залишок' })
  lowStock() {
    return this.service.findLowStock();
  }

  @Post()
  @ApiOperation({ summary: 'POST /medications — додати медикамент' })
  create(@Body() dto: Partial<Medication>) {
    return this.service.createMedication(dto);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() dto: Partial<Medication>) {
    return this.service.updateMedication(id, dto);
  }
}

@ApiTags('pharmacy')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('prescriptions')
export class PrescriptionsController {
  constructor(private service: PharmacyService) {}

  @Get('patient/:patientId')
  @ApiOperation({ summary: 'GET /prescriptions/patient/:id — рецепти пацієнта' })
  byPatient(@Param('patientId') patientId: string) {
    return this.service.findPrescriptionsByPatient(patientId);
  }

  @Post()
  @ApiOperation({ summary: 'POST /prescriptions — виписати рецепт' })
  create(@Body() dto: Partial<Prescription>) {
    return this.service.createPrescription(dto);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'PATCH /prescriptions/:id — оновити рецепт' })
  update(@Param('id') id: string, @Body() dto: any) {
    return this.service.updatePrescription(id, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'DELETE /prescriptions/:id — видалити рецепт' })
  remove(@Param('id') id: string) {
    return this.service.deletePrescription(id);
  }
}
