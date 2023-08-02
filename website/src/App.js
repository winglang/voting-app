import React, { useState, useEffect } from "react";

const Table = () => {
  const [data, setData] = useState([]);
  useEffect(() => {
    // Function to fetch data from the endpoint
    const fetchData = async () => {
      try {
        const config = await fetch("./config.json");
        const baseUrl = (await config.json()).apiUrl;
        const response = await fetch(baseUrl + "/items", {

        });
        if (!response.ok) {
          throw new Error('Failed to fetch data');
        }
        const jsonData = await response.json();
        setData(jsonData);
      } catch (error) {
        console.error('Error fetching data:', error);
      }
    };

    fetchData(); // Call the fetch function when the component mounts
  }, []);

  return (
    <div>
      <h2>Data Table</h2>
      <table>
        <thead>
          <tr>
            <th>Name</th>
            <th>Score</th>
          </tr>
        </thead>
        <tbody>
          {data.map((item) => (
            <tr key={item.Name}>
              <td>{item.Name}</td>
              <td>{item.Score}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

function App() {
  return (
    <Table />
  );
}

export default App;
