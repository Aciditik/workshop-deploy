const { PrismaClient } = require("@prisma/client");
const bcrypt = require("bcryptjs");
const prisma = new PrismaClient();

async function seed() {
  try {
    const existing = await prisma.user.findUnique({ where: { email: "admin@cdf.com" } });
    if (!existing) {
      const hash = await bcrypt.hash(process.env.ADMIN_PASSWORD || "#Pxqz#6Y5z!rxAa$", 10);
      await prisma.user.create({ 
        data: { 
          email: "admin@cdf.com", 
          password: hash, 
          role: "admin", 
          name: "Admin CDF" 
        } 
      });
      console.log("✓ Admin user created: admin@cdf.com");
    } else {
      console.log("✓ Admin user already exists");
    }
  } catch (error) {
    console.error("Seed error:", error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

seed();
