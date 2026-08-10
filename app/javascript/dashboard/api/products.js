/* global axios */
import ApiClient from './ApiClient';

class ProductAPI extends ApiClient {
  constructor() {
    super('products', { accountScoped: true });
  }

  getProducts() {
    return axios.get(this.url);
  }

  createProduct(data) {
    return axios.post(this.url, { product: data });
  }

  updateProduct(id, data) {
    return axios.patch(`${this.url}/${id}`, { product: data });
  }

  deleteProduct(id) {
    return axios.delete(`${this.url}/${id}`);
  }
}

export default new ProductAPI();