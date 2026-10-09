import axios from "axios";

const BASE_URL = import.meta.env.VITE_API_URL;

export const fetchUsers = async () => {
  try {
    const response = await axios.get(`${BASE_URL}/api/users`);
    return response.data;
  } catch (error) {
    console.error("Error fetching users:", error);
    throw error;
  }
};

export const registerUser = async (userData) => {
  try {
    const response = await axios.post(
      `${BASE_URL}/api/register`,
      userData
    );
    return response.data;
  } catch (error) {
    console.error("Error registering user:", error);
    throw error;
  }
};

export const deleteUser = async (id) => {
  try {
    await axios.delete(`${BASE_URL}/api/users/${id}`);
  } catch (error) {
    console.error("Error deleting user:", error);
    throw error;
  }
};

