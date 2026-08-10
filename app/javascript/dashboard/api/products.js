import axios from 'axios';

const url = accountId => `/api/v1/accounts/${accountId}/products`;

export default {
  getProducts(accountId) {
    return axios.get(url(accountId));
  },
  createProduct(accountId, data) {
    return axios.post(url(accountId), { product: data });
  },
  updateProduct(accountId, id, data) {
    return axios.patch(`${url(accountId)}/${id}`, { product: data });
  },
  deleteProduct(accountId, id) {
    return axios.delete(`${url(accountId)}/${id}`);
  },
};