#!/bin/bash

echo "🚀 Starting MedCare CRM Backend Setup..."

# 1. Kill everything on ports 3000 and 3001
echo "🧹 Cleaning ports 3000 and 3001..."
lsof -ti:3000,3001 | xargs kill -9 2>/dev/null || true

# 2. Start Docker Containers
echo "🐳 Starting Docker containers..."
docker compose down
docker compose up -d --build

# 3. Wait for Database to be ready
echo "⏳ Waiting for Database (PostgreSQL) to initialize..."
sleep 12

# 4. Seed database and fix password
echo "💾 Seeding database and setting password 'password123' for doctor@medcare.ua..."
docker exec -i medcare-nestjs-api node -e "
const bcrypt = require('bcryptjs');
const pg = require('pg');
const pool = new pg.Pool({ user: 'postgres', host: 'medcare-postgres', database: 'medcare', password: 'postgres', port: 5432 });

async function seed() {
  try {
    const hash = bcrypt.hashSync('password123', 12);
    
    // 1. Update/Fix main doctor user
    await pool.query(\"UPDATE users SET password = \$1 WHERE email = 'doctor@medcare.ua'\", [hash]);
    
    // 2. Ensure Doctor entity exists
    const userId = (await pool.query(\"SELECT id FROM users WHERE email = 'doctor@medcare.ua'\")).rows[0].id;
    await pool.query(\"INSERT INTO doctors (id, \\\"userId\\\", \\\"firstName\\\", \\\"lastName\\\", specialization, \\\"licenseNo\\\", \\\"officeNumber\\\") VALUES (uuid_generate_v4(), \$1, 'Олена', 'Іваненко', 'Загальна практика', 'UA-GP-123', '101') ON CONFLICT DO NOTHING\", [userId]);
    
    // 3. Add Patients
    await pool.query(\"INSERT INTO patients (id, \\\"firstName\\\", \\\"lastName\\\", \\\"birthDate\\\", phone) VALUES (uuid_generate_v4(), 'Олексій', 'Петренко', '1985-05-12', '+380671112233') ON CONFLICT DO NOTHING\");
    await pool.query(\"INSERT INTO patients (id, \\\"firstName\\\", \\\"lastName\\\", \\\"birthDate\\\", phone) VALUES (uuid_generate_v4(), 'Марина', 'Коваль', '1992-08-24', '+380504445566') ON CONFLICT DO NOTHING\");
    
    console.log('✅ Success: Backend is ready and seeded!');
    process.exit(0);
  } catch (e) {
    console.error('❌ Error during seeding:', e);
    process.exit(1);
  }
}
seed();
"

echo "------------------------------------------------"
echo "🔥 MedCare CRM is live!"
echo "API: http://localhost:3001/api"
echo "Docs: http://localhost:3001/api/docs"
echo "Credentials: doctor@medcare.ua / password123"
echo "------------------------------------------------"
