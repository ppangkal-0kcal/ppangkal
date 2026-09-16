-- DropForeignKey
ALTER TABLE "food_logs" DROP CONSTRAINT "food_logs_bread_item_id_fkey";

-- AlterTable
ALTER TABLE "food_logs" ADD COLUMN     "custom_name" TEXT,
ALTER COLUMN "bread_item_id" DROP NOT NULL;

-- AddForeignKey
ALTER TABLE "food_logs" ADD CONSTRAINT "food_logs_bread_item_id_fkey" FOREIGN KEY ("bread_item_id") REFERENCES "bread_items"("id") ON DELETE SET NULL ON UPDATE CASCADE;

