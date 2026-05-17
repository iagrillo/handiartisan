import '../models/category.dart';

// List of all artisan categories
final List<Category> categories = [
	// Construction & Building Trades
	Category(slug: 'bricklayer', name: 'Bricklayers / Masons', icon: 'Home'),
	Category(slug: 'carpenter', name: 'Carpenters', icon: 'Settings'),
	Category(slug: 'plumber', name: 'Plumbers', icon: 'Settings'),
	Category(slug: 'electrician', name: 'Electricians (installation & maintenance)', icon: 'Shield'),
	Category(slug: 'welder', name: 'Welders', icon: 'Settings'),
	Category(slug: 'painter', name: 'Painters', icon: 'Edit'),
	Category(slug: 'tiler', name: 'Tilers', icon: 'Home'),
	Category(slug: 'roofer', name: 'Roofers', icon: 'Home'),
	Category(slug: 'concrete-worker', name: 'Concrete workers', icon: 'Home'),
	Category(slug: 'draughtsman', name: 'Draughtsmen / Survey assistants', icon: 'Edit'),

	// Auto & Mechanical Services
	Category(slug: 'car-mechanic', name: 'Car mechanics', icon: 'Settings'),
	Category(slug: 'motorcycle-repairer', name: 'Motorcycle repairers', icon: 'Settings'),
	Category(slug: 'truck-mechanic', name: 'Truck & heavy-duty mechanics', icon: 'Settings'),
	Category(slug: 'panel-beater', name: 'Panel beaters', icon: 'Settings'),
	Category(slug: 'spray-painter', name: 'Spray painters', icon: 'Edit'),
	Category(slug: 'vulcanizer', name: 'Vulcanizers (tyre repair)', icon: 'Shield'),
	Category(slug: 'auto-electrician', name: 'Auto electricians', icon: 'Shield'),

	// Fashion, Beauty & Personal Care
	Category(slug: 'tailor', name: 'Tailors / Fashion designers', icon: 'Edit'),
	Category(slug: 'shoemaker', name: 'Shoemakers / Leather workers', icon: 'Edit'),
	Category(slug: 'barber', name: 'Barbers', icon: 'User'),
	Category(slug: 'hair-stylist', name: 'Hair stylists', icon: 'User'),
	Category(slug: 'makeup-artist', name: 'Makeup artists', icon: 'Star'),
	Category(slug: 'spa-therapist', name: 'Spa & massage therapists', icon: 'Heart'),
	Category(slug: 'bead-maker', name: 'Bead makers / Jewelry artisans', icon: 'Star'),

	// Home & Domestic Services
	Category(slug: 'housekeeper', name: 'Housekeepers', icon: 'User'),
	Category(slug: 'nanny', name: 'Nannies / Babysitters', icon: 'User'),
	Category(slug: 'gardener', name: 'Gardeners', icon: 'User'),
	Category(slug: 'laundry-worker', name: 'Laundry workers', icon: 'User'),
	Category(slug: 'dry-cleaner', name: 'Dry cleaners', icon: 'User'),
	Category(slug: 'pest-control', name: 'Pest control / fumigation specialists', icon: 'Shield'),

	// Technical & Electrical Trades
	Category(slug: 'ac-repairer', name: 'Refrigeration & AC repairers', icon: 'Shield'),
	Category(slug: 'electronics-technician', name: 'Electronics technicians', icon: 'Settings'),
	Category(slug: 'computer-repairer', name: 'Computer repairers', icon: 'Settings'),
	Category(slug: 'phone-technician', name: 'Phone technicians', icon: 'Settings'),
	Category(slug: 'solar-installer', name: 'Solar panel installers', icon: 'Star'),
	Category(slug: 'generator-repairer', name: 'Generator repairers', icon: 'Settings'),

	// Food, Events & Entertainment
	Category(slug: 'caterer', name: 'Caterers', icon: 'Star'),
	Category(slug: 'baker', name: 'Bakers', icon: 'Star'),
	Category(slug: 'event-decorator', name: 'Event decorators', icon: 'Edit'),
	Category(slug: 'event-planner', name: 'Event planners', icon: 'Edit'),
	Category(slug: 'photographer', name: 'Photographers', icon: 'Star'),
	Category(slug: 'videographer', name: 'Videographers', icon: 'Star'),
	Category(slug: 'dj', name: 'DJs', icon: 'Star'),
	Category(slug: 'musician', name: 'Musicians (traditional artisans in cultural contexts)', icon: 'Star'),

	// Traditional Crafts & Skilled Work
	Category(slug: 'blacksmith', name: 'Blacksmiths', icon: 'Settings'),
	Category(slug: 'potter', name: 'Potters', icon: 'Edit'),
	Category(slug: 'sculptor', name: 'Sculptors', icon: 'Star'),
	Category(slug: 'weaver', name: 'Weavers', icon: 'Edit'),
	Category(slug: 'basket-maker', name: 'Basket makers', icon: 'Edit'),
	Category(slug: 'traditional-leather', name: 'Traditional leather workers (notably in Kano)', icon: 'Edit'),
	Category(slug: 'wood-carver', name: 'Wood carvers', icon: 'Edit'),
	Category(slug: 'drummer', name: 'Drummers / instrument makers', icon: 'Star'),

	// Miscellaneous Services
	Category(slug: 'driver', name: 'Drivers', icon: 'User'),
	Category(slug: 'security-guard', name: 'Security guards', icon: 'Shield'),
	Category(slug: 'furniture-maker', name: 'Furniture makers', icon: 'Settings'),
	Category(slug: 'sign-writer', name: 'Sign writers', icon: 'Edit'),
	Category(slug: 'cleaning-service', name: 'Cleaning service providers (domestic, industrial, post-construction)', icon: 'User'),

	// Other
	Category(slug: 'other', name: 'Other (please specify)', icon: 'Help'),
];

// Utility: Find a category by slug
Category? getCategoryBySlug(String slug) {
	return categories.firstWhere((c) => c.slug == slug, orElse: () => Category(slug: slug, name: slug, icon: 'Help', id: 0));
}

// Utility: Filter categories by name
List<Category> filterCategories(String query) {
	return categories.where((c) => c.name.toLowerCase().contains(query.toLowerCase())).toList();
}
