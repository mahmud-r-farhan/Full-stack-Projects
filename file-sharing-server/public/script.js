
document.addEventListener('DOMContentLoaded', () => {
    const fileList = document.getElementById('fileList');
    const searchInput = document.getElementById('search');
    const searchButton = document.getElementById('search-btn');
    
    document.body.appendChild(searchButton);

    const downloadRecentButton = document.getElementById('recent-download-btn');
 
    document.body.appendChild(downloadRecentButton);

    fetch('/files')
        .then(response => response.json())
        .then(files => {
            displayFiles(files);

            searchButton.addEventListener('click', () => {
                const searchTerm = searchInput.value.toLowerCase();
                const filteredFiles = files.filter(file => file.toLowerCase().includes(searchTerm));
                displayFiles(filteredFiles);
            });

            // Sort files by upload time (assuming filenames contain timestamps)
            files.sort((a, b) => {
                const timeA = new Date(a.split('-').pop().split('.')[0]);
                const timeB = new Date(b.split('-').pop().split('.')[0]);
                return timeB - timeA;
            });

            // Set the most recent file for download
            if (files.length > 0) {
                const mostRecentFile = files[0];
                downloadRecentButton.onclick = () => {
                    window.location.href = `/download/${mostRecentFile}`;
                };
            }
        })
        .catch(error => console.error('Error fetching files:', error));


function displayFiles(files) {
    fileList.innerHTML = '';
    files.forEach(file => {
        const listItem = document.createElement('li');
        listItem.textContent = file;
        fileList.appendChild(listItem);
    });
}


    function displayFiles(files) {
      fileList.innerHTML = '';
      files.forEach(file => {
        const listItem = document.createElement('li');
        const link = document.createElement('p');
        link.href = `/download/${file}`;
        link.textContent = file;
        link.download = file;

        const downloadButton = document.createElement('button');
        downloadButton.textContent = 'Download';
        downloadButton.onclick = () => {
          window.location.href = `/download/${file}`;
        };

        const deleteButton = document.createElement('button');
        deleteButton.textContent = 'Delete';
        deleteButton.onclick = () => {
            if (confirm(`Are you sure you want to delete ${file}?`)) {
              fetch(`/delete/${file}`, {
                method: 'DELETE'
              })
              .then(response => {
                if (!response.ok) {
                  throw new Error('Error deleting file');
                }
                return response.text();
              })
              .then(data => {
                console.log(data);
                // Refresh the file list after deletion
                fetch('/files')
                  .then(response => response.json())
                  .then(files => displayFiles(files));
              })
              .catch(error => console.error('Error deleting file:', error));
            }
          };
          

        // Add preview for images and videos
        const preview = document.createElement('div');
        if (file.match(/\.(jpeg|jpg|png|gif)$/)) {
          const img = document.createElement('img');
          img.src = `/uploads/${file}`;
          img.style.maxWidth = '200px';
          preview.appendChild(img);
        } else if (file.match(/\.(mp4|mov|avi)$/)) {
          const video = document.createElement('video');
          video.src = `/uploads/${file}`;
          video.controls = true;
          video.style.maxWidth = '200px';
          preview.appendChild(video);
        }

        listItem.appendChild(link);
        listItem.appendChild(downloadButton);
        listItem.appendChild(deleteButton);
        listItem.appendChild(preview);
        fileList.appendChild(listItem);
      });
    }

    // Handle file upload
    const uploadButton = document.getElementById('uploadButton');
    uploadButton.addEventListener('click', () => {
      const fileInput = document.getElementById('fileUpload');
      const file = fileInput.files[0];
      const formData = new FormData();
      formData.append('myFile', file);

      fetch('/upload', {
        method: 'POST',
        body: formData
      })
      .then(response => response.text())
      .then(data => {
        console.log(data);
        // Refresh the file list after upload
        fetch('/files')
          .then(response => response.json())
          .then(files => displayFiles(files));
      })
      .catch(error => console.error('Error uploading file:', error));
    });
  });
