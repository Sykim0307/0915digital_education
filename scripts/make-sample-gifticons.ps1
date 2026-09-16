Add-Type -AssemblyName System.Drawing

function New-GiftImage {
    param(
        [string]$Path,
        [string]$Brand,
        [string]$Product,
        [string]$PriceText,
        [string]$Expiry
    )
    $w = 500; $h = 700
    $bmp = [System.Drawing.Bitmap]::new($w, $h)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

    $g.Clear([System.Drawing.Color]::White)

    $bannerBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(254,229,0))
    $g.FillRectangle($bannerBrush, 0, 0, $w, 120)

    $fontTitle = [System.Drawing.Font]::new("Malgun Gothic", 20, [System.Drawing.FontStyle]::Bold)
    $darkBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(60,50,20))
    $g.DrawString("선물이 도착했어요", $fontTitle, $darkBrush, 30, 45)

    $iconBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(240,240,240))
    $g.FillEllipse($iconBrush, ($w/2 - 90), 160, 180, 180)
    $iconPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(220,220,220), 2)
    $g.DrawEllipse($iconPen, ($w/2 - 90), 160, 180, 180)

    $sf = [System.Drawing.StringFormat]::new()
    $sf.Alignment = [System.Drawing.StringAlignment]::Center

    $fontBrand = [System.Drawing.Font]::new("Malgun Gothic", 16)
    $grayBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(120,120,120))
    $g.DrawString($Brand, $fontBrand, $grayBrush, [System.Drawing.RectangleF]::new(0,370,$w,30), $sf)

    $fontProduct = [System.Drawing.Font]::new("Malgun Gothic", 24, [System.Drawing.FontStyle]::Bold)
    $blackBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(30,30,30))
    $g.DrawString($Product, $fontProduct, $blackBrush, [System.Drawing.RectangleF]::new(20,410,($w-40),80), $sf)

    $linePen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(230,230,230), 2)
    $g.DrawLine($linePen, 40, 520, ($w-40), 520)

    $fontPrice = [System.Drawing.Font]::new("Malgun Gothic", 18, [System.Drawing.FontStyle]::Bold)
    $redBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(200,50,40))
    $g.DrawString($PriceText, $fontPrice, $redBrush, [System.Drawing.RectangleF]::new(0,545,$w,35), $sf)

    $fontSmall = [System.Drawing.Font]::new("Malgun Gothic", 12)
    $g.DrawString("유효기간: $Expiry", $fontSmall, $grayBrush, [System.Drawing.RectangleF]::new(0,600,$w,25), $sf)

    $g.Dispose()
    $bmp.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
}

$dir = "C:\Users\user\Desktop\project\sample-images"
New-Item -ItemType Directory -Force -Path $dir | Out-Null

New-GiftImage -Path "$dir\gifticon-1-starbucks.png"   -Brand "스타벅스"     -Product "아메리카노 Tall"     -PriceText "4,500원"  -Expiry "2026.12.31"
New-GiftImage -Path "$dir\gifticon-2-kyochon.png"     -Brand "교촌치킨"     -Product "허니콤보"            -PriceText "23,000원" -Expiry "2026.11.30"
New-GiftImage -Path "$dir\gifticon-3-oliveyoung.png"  -Brand "올리브영"     -Product "모바일 상품권"       -PriceText "30,000원" -Expiry "2027.03.15"
New-GiftImage -Path "$dir\gifticon-4-baskin.png"      -Brand "배스킨라빈스" -Product "파인트 아이스크림"   -PriceText "9,500원"  -Expiry "2026.10.20"
New-GiftImage -Path "$dir\gifticon-5-emart.png"       -Brand "이마트"       -Product "상품권 5만원권"      -PriceText "50,000원" -Expiry "2027.06.30"

Write-Output "Done. Files in $dir :"
Get-ChildItem $dir | Select-Object Name, Length
