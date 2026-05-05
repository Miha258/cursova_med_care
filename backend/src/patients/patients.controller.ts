import { Controller, Get, Post, Patch, Delete, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { PatientsService } from './patients.service';
import { CreatePatientDto } from './dto/create-patient.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('patients')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('patients')
export class PatientsController {
  constructor(private service: PatientsService) {}

  @Get()
  @ApiQuery({ name: 'search', required: false })
  @ApiOperation({ summary: 'GET /patients — список + повнотекстовий пошук (pg_trgm)' })
  findAll(@Query('search') search?: string) {
    return this.service.findAll(search);
  }

  @Get('search')
  @ApiQuery({ name: 'q', required: true })
  @ApiOperation({ summary: 'GET /patients/search — пошук пацієнта' })
  search(@Query('q') q: string) {
    return this.service.findAll(q);
  }

  @Get(':id')
  @ApiOperation({ summary: 'GET /patients/:id — картка пацієнта (Redis TTL=5хв)' })
  findOne(@Param('id') id: string) {
    return this.service.findOne(id);
  }

  @Post()
  @ApiOperation({ summary: 'POST /patients — реєстрація пацієнта (HTTP 201 + UUID)' })
  create(@Body() dto: CreatePatientDto) {
    return this.service.create(dto);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'PATCH /patients/:id — оновлення даних пацієнта' })
  update(@Param('id') id: string, @Body() dto: Partial<CreatePatientDto>) {
    return this.service.update(id, dto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.service.remove(id);
  }
}
