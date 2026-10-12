const restaurants = [
  { id: 1, name: "Namma Meals", cuisine: "Indian Â· South Indian", category: "Indian", time: "22â€“28 min", price: 249, dish: "Masala dosa feast", tag: "Bestseller", image: "https://images.unsplash.com/photo-1630409351217-bc4fa6422075?auto=format&fit=crop&w=900&q=85" },
  { id: 2, name: "Luna Pasta Room", cuisine: "Italian Â· Handmade pasta", category: "Italian", time: "28â€“34 min", price: 389, dish: "Truffle mushroom pasta", tag: "New here", image: "https://images.unsplash.com/photo-1473093295043-cdd812d0e601?auto=format&fit=crop&w=900&q=85" },
  { id: 3, name: "Bowl & Bloom", cuisine: "Healthy Â· Salads & bowls", category: "Healthy", time: "18â€“24 min", price: 319, dish: "Rainbow grain bowl", tag: "Feel-good food", image: "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=900&q=85" },
  { id: 4, name: "Seoul Kitchen", cuisine: "Asian Â· Korean favourites", category: "Asian", time: "27â€“32 min", price: 359, dish: "Gochujang chicken bowl", tag: "Top rated", image: "https://images.unsplash.com/photo-1496116218417-1a781b1c416c?auto=format&fit=crop&w=900&q=85" },
  { id: 5, name: "Sugar & Stone", cuisine: "Dessert Â· Bakes & more", category: "Dessert", time: "19â€“25 min", price: 219, dish: "Burnt basque cheesecake", tag: "Just baked", image: "https://images.unsplash.com/photo-1565958011703-44f9829ba187?auto=format&fit=crop&w=900&q=85" },
  { id: 6, name: "Biryani District", cuisine: "Indian Â· Dum biryani", category: "Indian", time: "25â€“31 min", price: 299, dish: "Hyderabadi chicken biryani", tag: "Local favourite", image: "https://images.unsplash.com/photo-1563379926898-05f4575a45d8?auto=format&fit=crop&w=900&q=85" }
];

let cart = [];
let activeFilter = "all";
const grid = document.querySelector("#restaurantGrid");
const cartDrawer = document.querySelector("#cartDrawer");
const backdrop = document.querySelector("#backdrop");
const toast = document.querySelector("#toast");

function restaurantCard(restaurant) {
  return `<article class="restaurant-card" data-name="${restaurant.name.toLowerCase()} ${restaurant.cuisine.toLowerCase()} ${restaurant.dish.toLowerCase()}">
    <div class="restaurant-image" style="background-image:url('${restaurant.image}')"><span class="tag">${restaurant.tag}</span></div>
    <div class="restaurant-info"><h3>${restaurant.name}</h3><div class="restaurant-meta"><span class="rating">â˜… 4.${restaurant.id + 3}</span><span>â€¢</span><span>${restaurant.cuisine}</span></div>
      <div class="restaurant-bottom"><span><b>${restaurant.time}</b> Â· from â‚¹${restaurant.price}</span><button class="add-button" type="button" aria-label="Add ${restaurant.dish} to bag" data-id="${restaurant.id}">+</button></div>
    </div></article>`;
}

function renderRestaurants(query = "") {
  const normalized = query.toLowerCase().trim();
  const visible = restaurants.filter((restaurant) => (activeFilter === "all" || restaurant.category === activeFilter) && (!normalized || `${restaurant.name} ${restaurant.cuisine} ${restaurant.dish}`.toLowerCase().includes(normalized)));
  grid.innerHTML = visible.length ? visible.map(restaurantCard).join("") : `<p class="empty-cart">No kitchens found for that search. Try â€œbiryaniâ€ or â€œpastaâ€.</p>`;
}

function formatRupees(value) { return new Intl.NumberFormat("en-IN", { style: "currency", currency: "INR", maximumFractionDigits: 0 }).format(value); }

function updateCart() {
  const count = cart.reduce((total, item) => total + item.quantity, 0);
  const total = cart.reduce((sum, item) => sum + item.price * item.quantity, 0);
  document.querySelector("#cartCount").textContent = count;
  document.querySelector("#cartTotal").textContent = formatRupees(total);
  document.querySelector("#checkoutButton").disabled = cart.length === 0;
  document.querySelector("#cartItems").innerHTML = cart.length ? cart.map((item) => `<div class="cart-item"><div><h3>${item.dish} <span>Ã— ${item.quantity}</span></h3><p>${item.name}</p></div><div><strong>${formatRupees(item.price * item.quantity)}</strong><button class="remove-item" type="button" data-remove="${item.id}">Remove</button></div></div>`).join("") : `<p class="empty-cart">Your bag is waiting for something delicious.</p>`;
}

function addToCart(id) {
  const restaurant = restaurants.find((item) => item.id === Number(id));
  const existing = cart.find((item) => item.id === restaurant.id);
  if (existing) existing.quantity += 1;
  else cart.push({ ...restaurant, quantity: 1 });
  updateCart(); showToast(`${restaurant.dish} added to your bag`);
}

function showToast(message) { toast.textContent = message; toast.classList.add("show"); clearTimeout(showToast.timer); showToast.timer = setTimeout(() => toast.classList.remove("show"), 2500); }
function openCart() { cartDrawer.classList.add("open"); cartDrawer.setAttribute("aria-hidden", "false"); backdrop.hidden = false; }
function closeCart() { cartDrawer.classList.remove("open"); cartDrawer.setAttribute("aria-hidden", "true"); backdrop.hidden = true; }

document.querySelector("#restaurantGrid").addEventListener("click", (event) => { if (event.target.dataset.id) addToCart(event.target.dataset.id); });
document.querySelector("#cartItems").addEventListener("click", (event) => { if (event.target.dataset.remove) { const item = cart.find((cartItem) => cartItem.id === Number(event.target.dataset.remove)); if (item.quantity > 1) item.quantity -= 1; else cart = cart.filter((cartItem) => cartItem.id !== item.id); updateCart(); } });
document.querySelectorAll(".category").forEach((button) => button.addEventListener("click", () => { document.querySelector(".category.active").classList.remove("active"); button.classList.add("active"); activeFilter = button.dataset.filter; renderRestaurants(document.querySelector("#foodSearch").value); }));
document.querySelector("#searchForm").addEventListener("submit", (event) => { event.preventDefault(); renderRestaurants(event.currentTarget.food.value); document.querySelector("#restaurants").scrollIntoView({ behavior: "smooth" }); });
document.querySelector("#foodSearch").addEventListener("input", (event) => renderRestaurants(event.target.value));
document.querySelector("#openCart").addEventListener("click", openCart); document.querySelector("#closeCart").addEventListener("click", closeCart); backdrop.addEventListener("click", closeCart);
document.querySelector("#copyOffer").addEventListener("click", async () => { try { await navigator.clipboard.writeText("HELLOSAVORY"); } catch { /* Clipboard can be unavailable on local previews. */ } showToast("HELLOSAVORY copied â€” enjoy â‚¹100 off!"); });
document.querySelector("#checkoutButton").addEventListener("click", () => showToast("Checkout is ready to connect to your preferred payment provider."));
document.querySelector("#locationButton").addEventListener("click", () => showToast("Delivery location: MG Road, Bengaluru"));
document.querySelector("#showAll").addEventListener("click", () => { activeFilter = "all"; document.querySelector(".category.active").classList.remove("active"); document.querySelector('[data-filter="all"]').classList.add("active"); renderRestaurants(); });
document.querySelector("#year").textContent = new Date().getFullYear();
renderRestaurants(); updateCart();

