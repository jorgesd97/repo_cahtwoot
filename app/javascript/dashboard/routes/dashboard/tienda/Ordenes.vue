<template>
  <div class="w-full">
    <!-- TOOLBAR -->
    <div class="p-4 flex justify-between items-center border-b border-[#2A2E33] bg-[#151718]">
      <div class="relative w-64">
        <span class="absolute left-3 top-2.5 text-gray-500 text-sm">🔍</span>
        <input 
          type="text" 
          placeholder="Buscar Nro de orden..." 
          class="bg-[#151718] border border-[#2A2E33] text-white w-full rounded py-1.5 pl-9 pr-3 text-sm focus:outline-none focus:border-teal-500 transition"
          v-model="searchQuery"
          @input="debounceSearch"
        >
      </div>
    </div>

    <!-- TABLA -->
    <div class="bg-[#151718] rounded-b border-x border-b border-[#2A2E33] overflow-hidden">
      <table class="w-full text-left text-sm text-gray-300">
        <thead class="bg-[#151718] border-b border-[#2A2E33] text-xs text-gray-500 uppercase tracking-wide">
          <tr>
            <th class="px-5 py-4 font-medium">Nro Orden</th>
            <th class="px-5 py-4 font-medium">Estado</th>
            <th class="px-5 py-4 font-medium">Fecha Entrega</th>
            <th class="px-5 py-4 font-medium">Pedido</th>
            <th class="px-5 py-4 font-medium">Monto</th>
            <th class="px-5 py-4 font-medium text-right">Acciones</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="order in orders" :key="order.id" class="border-b border-[#2A2E33] hover:bg-[#1C1F21] transition">
            <td class="px-5 py-4">
              <div class="font-medium text-gray-200">#{{ order.order_number }}</div>
              <div class="text-[10px] text-gray-500">{{ formatDateShort(order.created_at) }}</div>
            </td>
            <td class="px-5 py-4">
              <span
                class="inline-flex items-center rounded px-2.5 py-0.5 text-[10px] font-bold uppercase tracking-wider border"
                :class="statusClass(order.status)"
              >
                {{ order.status }}
              </span>
            </td>
            <td class="px-5 py-4">
              <div class="text-teal-400 text-xs font-medium mb-1">{{ formatDeliveryDate(order) }}</div>
              <div class="text-[10px] text-gray-400 leading-tight">{{ order.delivery_address || '—' }}</div>
            </td>
            <td class="px-5 py-4 text-xs text-gray-300 leading-snug" v-html="formatItems(order.items_json)"></td>
            <td class="px-5 py-4 font-bold text-white">S/ {{ parseFloat(order.total_amount || 0).toFixed(2) }}</td>
            <td class="px-5 py-4 text-right">
              <div class="flex flex-col items-end gap-1.5">
                <button
                  v-if="order.status === 'pendiente'"
                  @click="updateStatus(order.id, 'enviado')"
                  class="text-gray-400 hover:text-teal-400 transition bg-[#212529] px-3 py-1.5 rounded border border-[#2A2E33] text-[10px] w-28"
                >
                  Marcar Enviado
                </button>
                <button
                  v-if="order.status === 'enviado'"
                  @click="updateStatus(order.id, 'entregado')"
                  class="text-gray-400 hover:text-green-400 transition bg-[#212529] px-3 py-1.5 rounded border border-[#2A2E33] text-[10px] w-28"
                >
                  Marcar Entregado
                </button>
                <button
                  v-if="order.status !== 'cancelado' && order.status !== 'entregado'"
                  @click="cancelOrder(order.id)"
                  class="text-red-400 hover:text-red-300 text-[10px] uppercase font-bold mt-1 transition text-right w-28"
                >
                  Cancelar
                </button>
              </div>
            </td>
          </tr>
          <tr v-if="orders.length === 0">
            <td colspan="6" class="px-5 py-8 text-center text-gray-500">
              No hay órdenes registradas.
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import axios from 'axios';

function debounce(fn, delay) {
  let timeoutId;
  return function (...args) {
    clearTimeout(timeoutId);
    timeoutId = setTimeout(() => fn.apply(this, args), delay);
  };
}

function getAuthHeaders() {
  // Opción 1: localStorage (devise_token_auth)
  try {
    const raw = localStorage.getItem('auth_headers');
    if (raw) {
      const h = JSON.parse(raw);
      if (h['access-token']) {
        return {
          'access-token': h['access-token'],
          'client': h['client'],
          'uid': h['uid'],
        };
      }
    }
  } catch (e) {}

  // Opción 2: cookie cw_d_session_info
  try {
    const match = document.cookie.match(/cw_d_session_info=([^;]+)/);
    if (match) {
      const data = JSON.parse(decodeURIComponent(match[1]));
      if (data['access-token'] || data['authorization']) {
        return {
          'access-token': data['access-token'],
          'client': data['client'],
          'uid': data['uid'],
        };
      }
    }
  } catch (e) {}

  // Opción 3: leer de Vuex store si está disponible globalmente
  try {
    const store = window.__VUE_APP__?.$store || document.querySelector('#app')?.__vue_app__?.$store;
    if (store && store.state.auth && store.state.auth.headers) {
      const h = store.state.auth.headers;
      return {
        'access-token': h['access-token'],
        'client': h['client'],
        'uid': h['uid'],
      };
    }
  } catch (e) {}

  return {};
}

export default {
  name: 'Ordenes',
  data() {
    return {
      orders: [],
      searchQuery: '',
      isLoading: false,
    };
  },
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
    }),
  },
  mounted() {
    this.fetchOrders();
  },
  methods: {
    async fetchOrders() {
      this.isLoading = true;
      try {
        const params = {};
        if (this.searchQuery) params.q = this.searchQuery;
        const { data } = await axios.get(`/api/v1/accounts/${this.accountId}/orders`, {
          params,
          headers: getAuthHeaders(),
        });
        this.orders = data;
      } catch (e) {
        console.error('Error fetching orders:', e);
        this.$toast.error('Error al cargar órdenes');
      } finally {
        this.isLoading = false;
      }
    },
    debounceSearch: debounce(function () {
      this.fetchOrders();
    }, 300),
    formatDateShort(dateStr) {
      const d = new Date(dateStr);
      return d.toLocaleDateString('es-PE', { day: '2-digit', month: 'short' });
    },
    formatDeliveryDate(order) {
      if (!order.delivery_date) return 'Inmediato (Email)';
      const d = new Date(order.delivery_date);
      const h = d.getHours().toString().padStart(2, '0');
      const hEnd = (d.getHours() + 4).toString().padStart(2, '0');
      return `${d.toLocaleDateString('es-PE', { day: '2-digit', month: 'short', year: 'numeric' })}, ${h}:00 - ${hEnd}:00`;
    },
    formatItems(itemsJson) {
      try {
        const items = typeof itemsJson === 'string' ? JSON.parse(itemsJson) : itemsJson;
        if (!Array.isArray(items)) return itemsJson || '—';
        return items.map(i => `${i.qty}x ${i.title}`).join('<br>');
      } catch {
        return itemsJson || '—';
      }
    },
    statusClass(status) {
      const map = {
        pendiente: 'bg-yellow-900/30 border-yellow-800 text-yellow-500',
        enviado: 'bg-blue-900/30 border-blue-800 text-blue-400',
        entregado: 'bg-green-900/30 border-green-800 text-green-400',
        cancelado: 'bg-red-900/30 border-red-800 text-red-400',
      };
      return map[status] || 'bg-gray-900/30 border-gray-800 text-gray-500';
    },
    async updateStatus(id, newStatus) {
      try {
        await axios.patch(`/api/v1/accounts/${this.accountId}/orders/${id}`, {
          order: { status: newStatus },
        }, { headers: getAuthHeaders() });
        this.$toast.success(`Orden marcada como ${newStatus}`);
        this.fetchOrders();
      } catch {
        this.$toast.error('Error al actualizar estado');
      }
    },
    cancelOrder(id) {
      this.$alert({
        title: '¿Cancelar orden?',
        message: 'Esta acción no se puede deshacer.',
        confirmLabel: 'Sí, cancelar',
        cancelLabel: 'No',
        onConfirm: () => this.updateStatus(id, 'cancelado'),
      });
    },
  },
};
</script>