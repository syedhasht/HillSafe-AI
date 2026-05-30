import os
from PIL import Image, ImageDraw

def generate_icons():
    logo_path = "assets/images/Logo.jpeg"
    out_icon_path = "assets/images/app_icon.png"
    out_foreground_path = "assets/images/app_icon_foreground.png"

    print("Opening source logo:", logo_path)
    logo = Image.open(logo_path).convert("RGBA")
    
    # 1. Create the main app icon (app_icon.png)
    # A beautiful filled circle icon containing the logo
    size = 512
    icon = Image.new("RGBA", (size, size), (255, 255, 255, 0)) # transparent background
    
    # Draw solid white circle
    draw = ImageDraw.Draw(icon)
    margin = 8
    draw.ellipse([margin, margin, size - margin, size - margin], fill=(255, 255, 255, 255))
    
    # Crop source logo to a circle and fit it inside the white circle
    logo_resized = logo.resize((size - margin*2, size - margin*2), Image.Resampling.LANCZOS)
    
    # Create circular mask for logo
    mask = Image.new("L", (size - margin*2, size - margin*2), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.ellipse([0, 0, size - margin*2, size - margin*2], fill=255)
    
    # Paste logo onto the icon using the mask
    icon.paste(logo_resized, (margin, margin), mask)
    
    # Save the main app icon
    icon.save(out_icon_path, "PNG")
    print("Saved filled circular app icon to:", out_icon_path)
    
    # 2. Create the adaptive foreground icon (app_icon_foreground.png)
    # The logo should be placed inside the 66% safe zone of a 512x512 transparent canvas
    foreground = Image.new("RGBA", (size, size), (255, 255, 255, 0))
    
    # The safe zone is ~320x320 pixels
    safe_size = 320
    safe_margin = (size - safe_size) // 2
    
    logo_safe = logo.resize((safe_size, safe_size), Image.Resampling.LANCZOS)
    
    # Create circular mask for safe zone logo
    safe_mask = Image.new("L", (safe_size, safe_size), 0)
    safe_mask_draw = ImageDraw.Draw(safe_mask)
    safe_mask_draw.ellipse([0, 0, safe_size, safe_size], fill=255)
    
    # Paste safe zone logo in the center of the transparent foreground canvas
    foreground.paste(logo_safe, (safe_margin, safe_margin), safe_mask)
    
    # Save adaptive foreground
    foreground.save(out_foreground_path, "PNG")
    print("Saved adaptive foreground icon to:", out_foreground_path)

if __name__ == "__main__":
    generate_icons()
