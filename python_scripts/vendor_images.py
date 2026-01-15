import os
from supabase import create_client, Client
from collections import defaultdict


SUPABASE_URL = 'https://cocmclecxanepyheygqs.supabase.co'
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNvY21jbGVjeGFuZXB5aGV5Z3FzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MjUyMjA1MiwiZXhwIjoyMDc4MDk4MDUyfQ.ZW8JOkw2A1NTbL3R9lIHMXQK5CqNe_azkwwFQBF_-HU"  # NOT the anon key
BUCKET_NAME = "vendor-photos"

# Initialize Supabase client
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

def get_vendor_photos():
    """
    Fetches all photos organized by vendor folder.
    Returns a dictionary where:
    - Key: vendor folder name (e.g., "vendor1", "acme-corp")
    - Value: list of public URLs for all images in that vendor's folder
    
    Example structure in bucket:
    vendor-photos/
    ├── vendor1/
    │   ├── photo1.jpg
    │   ├── photo2.jpg
    │   └── logo.png
    ├── vendor2/
    │   └── banner.jpg
    
    Returns:
    {
        "vendor1": ["url1", "url2", "url3"],
        "vendor2": ["url1"]
    }
    """
    try:
        vendor_photos = defaultdict(list)
        
        # List all folders in the root of the bucket
        folders = supabase.storage.from_(BUCKET_NAME).list()
        
        for folder in folders:
            folder_name = folder['name']
            
            # Skip if it's a file (not a folder)
            # Folders have id=None in Supabase
            if folder.get('id') is not None:
                continue
            
            # Now list all files in this vendor's folder
            files = supabase.storage.from_(BUCKET_NAME).list(folder_name)
            
            for file in files:
                file_name = file['name']
                
                # Check if it's an image file
                if any(file_name.lower().endswith(ext) for ext in ['.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp', '.jfif']):
                    # Build the full path
                    file_path = f"{folder_name}/{file_name}"
                    
                    # Get the public URL
                    url = supabase.storage.from_(BUCKET_NAME).get_public_url(file_path)
                    
                    # Add to vendor's list
                    vendor_photos[folder_name].append(url)
        
        # Convert defaultdict to regular dict
        return dict(vendor_photos)
    
    except Exception as e:
        print(f"Error fetching vendor photos: {e}")
        return {}


def get_vendor_photos_recursive():
    """
    Recursively fetches photos for vendors with nested folder structures.
    Handles cases like:
    vendor-photos/
    ├── vendor1/
    │   ├── products/
    │   │   ├── item1.jpg
    │   │   └── item2.jpg
    │   └── logo.png
    
    Returns the same format - all photos for a vendor in one list.
    """
    try:
        vendor_photos = defaultdict(list)
        
        def list_vendor_files(vendor_name, current_path):
            """Recursively list all files in a vendor's folder tree"""
            files = supabase.storage.from_(BUCKET_NAME).list(current_path)
            
            for file in files:
                file_name = file['name']
                full_path = f"{current_path}/{file_name}"
                
                # If it's a folder, recurse into it
                if file.get('id') is None:
                    list_vendor_files(vendor_name, full_path)
                else:
                    # It's a file - check if it's an image
                    if any(file_name.lower().endswith(ext) for ext in ['.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp', 'jfif']):
                        url = supabase.storage.from_(BUCKET_NAME).get_public_url(full_path)
                        vendor_photos[vendor_name].append(url)
        
        # List all top-level folders (vendor folders)
        vendors = supabase.storage.from_(BUCKET_NAME).list()
        
        for vendor in vendors:
            vendor_name = vendor['name']
            
            # Skip if it's a file in the root
            if vendor.get('id') is not None:
                continue
            
            # Recursively get all photos for this vendor
            list_vendor_files(vendor_name, vendor_name)
        
        return dict(vendor_photos)
    
    except Exception as e:
        print(f"Error fetching vendor photos recursively: {e}")
        return {}


def get_vendor_photos_sorted():
    """
    Same as get_vendor_photos_recursive but returns URLs sorted alphabetically.
    Useful for consistent ordering.
    """
    vendor_photos = get_vendor_photos_recursive()
    
    # Sort URLs for each vendor
    for vendor in vendor_photos:
        vendor_photos[vendor].sort()
    
    return vendor_photos


def print_vendor_summary(vendor_photos):
    """Helper function to print a nice summary"""
    print(f"\nFound {len(vendor_photos)} vendors with photos:\n")
    
    for vendor_name, urls in vendor_photos.items():
        print(f"📁 {vendor_name} ({len(urls)} photos)")
        
        # Create the array format
        url_list = '["' + '", "'.join(urls) + '"]'
        print(f"   {url_list}")
        print()


# =============================================
# USAGE EXAMPLES
# =============================================
if __name__ == "__main__":
    print("Fetching vendor photos from Supabase bucket...\n")
    
    # Get all vendor photos (handles nested folders too)
    vendor_photos = get_vendor_photos_recursive()
    
    # Print summary
    print_vendor_summary(vendor_photos)
    
    # Access specific vendor's photos
    if vendor_photos:
        first_vendor = list(vendor_photos.keys())[0]
        print(f"\nExample - Accessing {first_vendor}'s photos:")
        for url in vendor_photos[first_vendor]:
            print(f"  {url}")
    
    # Or get as sorted
    print("\n" + "="*50)
    print("Getting sorted version...")
    sorted_photos = get_vendor_photos_sorted()
    print(f"Total vendors: {len(sorted_photos)}")