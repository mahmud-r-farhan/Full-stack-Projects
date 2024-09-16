const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 3000;

// Set storage engine
const storage = multer.diskStorage({
  destination: './uploads/',
  filename: (req, file, cb) => {
    cb(null, file.fieldname + '' + Date.now() + path.extname(file.originalname));
  }
});

// Init upload
const upload = multer({
  storage: storage,
  limits: { fileSize: 999999999 }, // set limit
  fileFilter: (req, file, cb) => {
    checkFileType(file, cb);
  }
}).single('myFile');

// Check file type
function checkFileType(file, cb) {
  const filetypes = /jpeg|jpg|png|gif|pdf|docx/;
  const extname = filetypes.test(path.extname(file.originalname).toLowerCase());
  const mimetype = filetypes.test(file.mimetype);

  if (mimetype && extname) {
    return cb(null, true);
  } else {
    cb('Error: Something went Wrong! visit: GITHUB, https://github.com/mahmud-r-farhan');
  }
}

// Set static folder
app.use(express.static('./public'));

app.post('/upload', (req, res) => {
  upload(req, res, (err) => {
    if (err) {
      res.send(err);
    } else {
      if (req.file == undefined) {
        res.send('No file selected!');
      } else {
        res.redirect('/');
      }
    }
  });
});

app.get('/files', (req, res) => {
  fs.readdir('./uploads', (err, files) => {
    if (err) {
      res.status(500).send('Error reading files');
    } else {
      res.json(files);
    }
  });
});

// Download file
app.get('/download/:filename', (req, res) => {
  const filename = req.params.filename;
  const filePath = path.join(__dirname, 'uploads', filename);

  res.download(filePath, (err) => {
    if (err) {
      console.error('Error downloading file:', err);
      res.status(500).send('Error downloading file');
    }
  });
});

// Delete file
app.delete('/delete/:filename', (req, res) => {
    const filename = req.params.filename;
    const filePath = path.join(__dirname, 'uploads', filename);
  
    fs.unlink(filePath, (err) => {
      if (err) {
        console.error('Error deleting file:', err);
        res.status(500).send('Error deleting file');
      } else {
        res.send(`File ${filename} deleted successfully`);
      }
    });
  });
  

app.listen(PORT, () => console.log(`Server started on port ${PORT}`));
