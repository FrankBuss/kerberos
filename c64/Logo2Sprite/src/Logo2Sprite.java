import java.awt.*;
import java.awt.image.*;

public class Logo2Sprite {
	static void setPixel(int[] pixels, int x, int y) {
		pixels[x + y * 48] = 1;
	}

	static void saveSprite(int[] pixels, String name) {
		for (int s = 0; s < 2; s++) {
			System.out.println((s == 0 ? "left" : "right") + name + ":");
			for (int y = 0; y < 21; y++) {
				System.out.print("\t.byte ");
				for (int c = 0; c < 3; c++) {
					int b = 0;
					for (int x = 0; x < 8; x++) {
						if (pixels[s * 24 + c * 8 + x + y * 48] == 1) {
							b |= 1 << (7 - x);
						}
					}
					String hex = Integer.toHexString(b);
					while (hex.length() < 2)
						hex = "0" + hex;
					if (c > 0)
						System.out.print(", ");
					System.out.print("$" + hex);
				}
				System.out.println();
			}
			System.out.println("\t.byte 0");
			System.out.println();
		}
	}

	public static void main(String args[]) throws Exception {
		// check arguments
		if (args.length != 1) {
			System.out.println("Usage: Logo2Sprite logo.png");
			return;
		}

		// load file
		Frame dummy = new Frame();
		String filename = args[0];
		Image gif = Toolkit.getDefaultToolkit().getImage(filename);
		MediaTracker tracker = new MediaTracker(dummy);
		tracker.addImage(gif, 0);
		tracker.waitForID(0);

		// get pixels
		int w = gif.getWidth(dummy);
		int h = gif.getHeight(dummy);
		int[] pixels = new int[w * h];
		PixelGrabber pg = new PixelGrabber(gif, 0, 0, w, h, pixels, 0, w);
		try {
			pg.grabPixels();
		} catch (InterruptedException e) {
		}

		// create sprites
		int[] orange = new int[48 * 21];
		int[] black = new int[48 * 21];
		for (int y = 0; y < h; y++) {
			for (int x = 0; x < w; x++) {
				int c = pixels[y * w + x];
				if (c == -3316187) {
					setPixel(orange, x, y);
				}
				if (c == -16777216) {
					setPixel(black, x, y);
				}
			}
		}

		// save sprites
		saveSprite(black, "Black");
		saveSprite(orange, "Orange");
	}
}