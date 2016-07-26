package main

import (
	"image"
	"image/color"
	"image/draw"
	"image/jpeg"
	"log"
	"math"
	"os"
)

func main() {
	input := os.Args[1]
	f, err := os.Open(input)
	if err != nil {
		log.Fatal(err)
	}
	img, err := jpeg.Decode(f)
	f.Close()
	if err != nil {
		log.Fatal(err)
	}

	text, bg := split(img)
	writeImage(text, input+".text.jpg")
	writeImage(bg, input+".bg.jpg")
}

func writeImage(img image.Image, out string) {
	f, err := os.Create(out)
	if err != nil {
		log.Printf("ERROR: %s", err)
		return
	}
	err = jpeg.Encode(f, img, nil)
	if err != nil {
		log.Printf("ERROR: %s", err)
	}
	err = f.Close()
	if err != nil {
		log.Printf("ERROR: %s", err)
	}
	log.Printf("wrote %s", out)
}

func asYCbCr(c color.Color) color.YCbCr {
	return color.YCbCrModel.Convert(c).(color.YCbCr)
}

func split(img image.Image) (textImg, bgImg image.Image) {
	size := img.Bounds().Max
	text := image.NewGray(img.Bounds())
	bg := image.NewRGBA(img.Bounds())
	// copy image to background
	draw.Src.Draw(bg, img.Bounds(), img, img.Bounds().Min)
	// make text white
	draw.Src.Draw(text, img.Bounds(), image.NewUniform(color.White), image.Point{})
	for x := 0; x+32 <= size.X; x += 16 {
		for y := 0; y+32 <= size.Y; y += 16 {
			pt := image.Point{X: x, Y: y}
			pt2 := image.Point{X: x + 32, Y: y + 32}
			col, ok := isBitonal(img, pt)
			if ok {
				// fill uniform
				draw.Src.Draw(bg, image.Rectangle{Min: pt, Max: pt2},
					image.NewUniform(col), image.Point{})
				// extract text
				ref := asYCbCr(col)
				for i := 0; i < 32; i++ {
					for j := 0; j < 32; j++ {
						col := asYCbCr(img.At(x+i, y+j))
						val := float64(col.Y) / float64(ref.Y) * 256
						if val >= 256 {
							val = 255
						}
						text.SetGray(x+i, y+j, color.Gray{uint8(val)})
					}
				}
			}
		}
	}
	return text, bg
}

var ybuf = image.NewYCbCr(
	image.Rectangle{Max: image.Point{32, 32}},
	image.YCbCrSubsampleRatio444)

// isBitonal tests whether the image is bitonal and if so,
// returns the background color value
func isBitonal(img image.Image, pt image.Point) (color.Color, bool) {
	// convert to YCbCr coordinates
	for x := 0; x < 32; x++ {
		for y := 0; y < 32; y++ {
			value := img.At(pt.X+x, pt.Y+y)
			v := asYCbCr(value)
			i := 32*y + x
			ybuf.Y[i] = v.Y
			ybuf.Cb[i] = v.Cb
			ybuf.Cr[i] = v.Cr
		}
	}

	// An image is bitonal if:
	// - more than 50% of the pixels have constant value (Y0, Cb0, Cr0)
	// - other pixels have identical hue, that is,
	//   (Cb, Cr) = (k * Cb0, k * Cr0)

	// find background color
	var ystats [256]int
	for _, y := range ybuf.Y {
		ystats[y]++
	}
	var z [256]int
	z[0] = ystats[0]
	var bestY uint8
	for i := range z {
		if i > 0 {
			z[i] = z[i-1] + ystats[i]
		}
		if i >= 16 {
			z[i] -= ystats[i-16]
		}
		if z[i] > z[bestY] {
			bestY = uint8(i)
		}
	}
	if z[bestY] <= len(ybuf.Y)/2 {
		return nil, false
	}

	// compute hue.
	var cb, cr float64
	for i := range ybuf.Y {
		if int(bestY-16) < int(ybuf.Y[i]) && ybuf.Y[i] <= bestY {
			cb += float64(ybuf.Cb[i])
			cr += float64(ybuf.Cr[i])
		}
	}
	cb /= float64(z[bestY])
	cr /= float64(z[bestY])

	// test uniformity
	for i := range ybuf.Y {
		if cb <= 16 {
			// handle horizontal/vertical hues
			if float64(ybuf.Cb[i]) >= cb+16 {
				return nil, false
			}
			continue
		}
		if cr <= 16 {
			if float64(ybuf.Cr[i]) >= cr+16 {
				return nil, false
			}
			continue
		}
		b := float64(ybuf.Cb[i]) / cb
		r := float64(ybuf.Cr[i]) / cr
		if math.Abs(b-r) >= 0.05 {
			return nil, false
		}
	}
	if bestY <= 16 {
		bestY /= 2
	} else {
		bestY -= 8
	}
	return color.YCbCr{Y: bestY, Cb: uint8(cb), Cr: uint8(cr)}, true
}
