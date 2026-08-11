import ProductAPI from '../../api/products';

const state = {
  products: [],
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
  },
};

const getters = {
  getProducts: state => state.products,
  getUIFlags: state => state.uiFlags,
};

const actions = {
  async fetchProducts({ commit }) {
    commit('setUIFlag', { isFetching: true });
    try {
      const { data } = await ProductAPI.getProducts();
      commit('setProducts', data);
    } catch (error) {
      console.error('Error cargando productos:', error);
    } finally {
      commit('setUIFlag', { isFetching: false });
    }
  },

  async importProducts({ dispatch }, file) {
  await ProductAPI.importProducts(file);
  dispatch('fetchProducts');
  },
  
  async createProduct({ dispatch }, product) {
    await ProductAPI.createProduct(product);
    dispatch('fetchProducts');
  },

  async updateProduct({ dispatch }, { id, product }) {
    await ProductAPI.updateProduct(id, product);
    dispatch('fetchProducts');
  },

  async deleteProduct({ dispatch }, id) {
    await ProductAPI.deleteProduct(id);
    dispatch('fetchProducts');
  },
};

const mutations = {
  setProducts(state, products) {
    state.products = products;
  },
  setUIFlag(state, data) {
    state.uiFlags = { ...state.uiFlags, ...data };
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};