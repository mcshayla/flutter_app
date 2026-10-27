// "Add to budget" for a YES vendor, shared by vendor pages and the YES page.
// Reads the button's data-budget-* attributes and adds a planned line to
// the Plan page's budget (browser or account, whichever store is passed).

import { budgetCategoryFor } from './plan-logic.js';
import { toast } from './dialog.js';

export async function addVendorToBudget(store, button) {
  const amount = Number(button.dataset.budgetAmount);
  try {
    await store.addBudgetItem({
      item_name: button.dataset.budgetName,
      category: budgetCategoryFor(button.dataset.category),
      estimated_cost: button.dataset.budgetAmount !== '' && Number.isFinite(amount) ? amount : 0,
      actual_cost: null,
      vendor_id: button.dataset.vendorId,
      is_paid: false,
      notes: '',
    });
    button.textContent = 'Added to budget';
    button.disabled = true;
    toast('Added to your budget. You\'ll find it in Planning Tools, under Budget.');
  } catch (err) {
    toast(`That didn't save. ${err.message}`);
  }
}
