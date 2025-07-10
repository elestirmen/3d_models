#!/bin/bash

# 3D Model Optimization Script
# Bu script, GLTF modelini ve texture dosyalarını optimize eder

echo "🚀 3D Model Optimization Script Başlatılıyor..."

# Gerekli paketlerin kontrolü ve yüklenmesi
echo "📦 Gerekli araçlar kontrol ediliyor..."

# Node.js ve npm kontrolü
if ! command -v node &> /dev/null; then
    echo "❌ Node.js bulunamadı. Lütfen Node.js yükleyin."
    exit 1
fi

if ! command -v npm &> /dev/null; then
    echo "❌ npm bulunamadı. Lütfen npm yükleyin."
    exit 1
fi

# GLTF Pipeline kurulumu
echo "🔧 GLTF Pipeline kuruluyor..."
npm install -g gltf-pipeline 2>/dev/null || {
    echo "⚠️  GLTF Pipeline kurulumu root gerektiriyor, local kurulum deneniyor..."
    npm install gltf-pipeline
    GLTF_CMD="npx gltf-pipeline"
}

if command -v gltf-pipeline &> /dev/null; then
    GLTF_CMD="gltf-pipeline"
else
    GLTF_CMD="npx gltf-pipeline"
fi

# ImageMagick kontrolü (texture optimizasyonu için)
if ! command -v convert &> /dev/null; then
    echo "⚠️  ImageMagick bulunamadı. Texture optimizasyonu atlanacak."
    IMAGEMAGICK_AVAILABLE=false
else
    IMAGEMAGICK_AVAILABLE=true
fi

# Backup klasörü oluşturma
echo "💾 Backup oluşturuluyor..."
BACKUP_DIR="kutuphane_backup_$(date +%Y%m%d_%H%M%S)"
cp -r kutuphane "$BACKUP_DIR"
echo "✅ Backup oluşturuldu: $BACKUP_DIR"

# GLTF Model Optimizasyonu
echo "🎯 GLTF modeli optimize ediliyor..."
cd kutuphane

if [ -f "Kutuphane.gltf" ]; then
    echo "  ⚙️  Draco sıkıştırması uygulanıyor..."
    $GLTF_CMD -i Kutuphane.gltf -o Kutuphane_optimized.gltf -d
    
    if [ -f "Kutuphane_optimized.gltf" ]; then
        # Orijinal dosya boyutları
        ORIGINAL_SIZE=$(du -sh Kutuphane.gltf | cut -f1)
        ORIGINAL_BIN_SIZE=$(du -sh Kutuphane.bin | cut -f1)
        
        # Optimize edilmiş dosya boyutları
        OPTIMIZED_SIZE=$(du -sh Kutuphane_optimized.gltf | cut -f1)
        OPTIMIZED_BIN_SIZE=$(du -sh Kutuphane_optimized.bin | cut -f1)
        
        echo "  📊 GLTF Optimizasyon Sonuçları:"
        echo "    • GLTF: $ORIGINAL_SIZE → $OPTIMIZED_SIZE"
        echo "    • BIN:  $ORIGINAL_BIN_SIZE → $OPTIMIZED_BIN_SIZE"
        
        # Optimize edilmiş dosyayı ana dosya olarak kullan
        mv Kutuphane.gltf Kutuphane_original.gltf
        mv Kutuphane.bin Kutuphane_original.bin
        mv Kutuphane_optimized.gltf Kutuphane.gltf
        mv Kutuphane_optimized.bin Kutuphane.bin
        
        echo "  ✅ GLTF optimizasyonu tamamlandı!"
    else
        echo "  ❌ GLTF optimizasyonu başarısız!"
    fi
else
    echo "  ❌ Kutuphane.gltf dosyası bulunamadı!"
fi

# Texture Optimizasyonu
if [ "$IMAGEMAGICK_AVAILABLE" = true ]; then
    echo "🖼️  Texture dosyaları optimize ediliyor..."
    
    # Her texture dosyasını optimize et
    for texture in scene_mesh_textured_material_*_map_Kd.jpg.jpeg; do
        if [ -f "$texture" ]; then
            echo "  🔄 Optimizing: $texture"
            
            # Orijinal boyut
            ORIGINAL_TEX_SIZE=$(du -sh "$texture" | cut -f1)
            
            # WebP formatına çevir (daha iyi sıkıştırma)
            WEBP_FILE="${texture%.*}.webp"
            convert "$texture" -quality 80 -define webp:method=6 "$WEBP_FILE"
            
            if [ -f "$WEBP_FILE" ]; then
                WEBP_SIZE=$(du -sh "$WEBP_FILE" | cut -f1)
                echo "    • $texture: $ORIGINAL_TEX_SIZE → $WEBP_SIZE (WebP)"
            fi
            
            # JPEG optimizasyonu da yap
            OPTIMIZED_FILE="${texture%.jpeg}_optimized.jpg"
            convert "$texture" -quality 75 -strip "$OPTIMIZED_FILE"
            
            if [ -f "$OPTIMIZED_FILE" ]; then
                OPTIMIZED_TEX_SIZE=$(du -sh "$OPTIMIZED_FILE" | cut -f1)
                echo "    • $texture: $ORIGINAL_TEX_SIZE → $OPTIMIZED_TEX_SIZE (JPEG)"
                
                # Orijinal dosyayı yedekle ve optimize edilmiş dosyayı kullan
                mv "$texture" "${texture%.jpeg}_original.jpeg"
                mv "$OPTIMIZED_FILE" "$texture"
            fi
        fi
    done
    
    echo "  ✅ Texture optimizasyonu tamamlandı!"
else
    echo "  ⚠️  ImageMagick bulunamadığı için texture optimizasyonu atlandı."
    echo "     Ubuntu/Debian: sudo apt-get install imagemagick"
    echo "     macOS: brew install imagemagick"
fi

# Sonuçları göster
cd ..
echo ""
echo "📊 Optimizasyon Sonuçları:"
echo "================================================"

echo "🗂️  Orijinal boyut:"
du -sh "$BACKUP_DIR"

echo "🗂️  Optimize edilmiş boyut:"
du -sh kutuphane

echo ""
echo "📋 Öneriler:"
echo "• Optimize edilmiş dosyaları test edin"
echo "• WebP texture dosyalarını kullanmak için GLTF dosyasını güncelleyin"
echo "• CDN kullanarak dosyaları hızlandırın"
echo "• Progressive loading implementasyonu yapın"

echo ""
echo "✅ Optimizasyon tamamlandı!"
echo "💾 Backup klasörü: $BACKUP_DIR"