document.addEventListener('DOMContentLoaded', () => {
    const playButton = document.getElementById('play');
    const pauseButton = document.getElementById('pause');
    const prevButton = document.getElementById('prev');
    const nextButton = document.getElementById('next');
    const progress = document.getElementById('progress');
    const volume = document.getElementById('volume');
    const speed = document.getElementById('speed');
    const playlist = document.getElementById('playlist');
    const recentSongs = document.getElementById('recent-songs');
    const audioUpload = document.getElementById('audio-upload');
    
    const recentSongLimit = 5; // Limit for recent songs
    const recentSongList = []; // Store recent songs
    
    let currentSongIndex = 0;
    
    const songs = [
        { title: 'Song 1', src: 'song1.mp3' },
        { title: 'Song 2', src: 'song2.mp3' },
        { title: 'Song 3', src: 'song3.mp3' }
    ];

    // Initialize WaveSurfer for the audio visualizer
    const wavesurfer = WaveSurfer.create({
        container: '#waveform',
        waveColor: 'violet',
        progressColor: 'purple',
        barWidth: 2
    });

    function loadSong(index) {
        const song = songs[index];
        wavesurfer.load(song.src);
        addRecentSong(song.title);
        updatePlaylist();
    }

    function updatePlaylist() {
        playlist.innerHTML = '';
        songs.forEach((song, index) => {
            const li = document.createElement('li');
            li.textContent = song.title;
            li.className = index === currentSongIndex ? 'font-bold' : '';
            li.addEventListener('click', () => {
                currentSongIndex = index;
                loadSong(currentSongIndex);
                wavesurfer.play();
            });
            playlist.appendChild(li);
        });
    }

    function addRecentSong(songTitle) {
        if (recentSongList.includes(songTitle)) return;
        recentSongList.unshift(songTitle);
        if (recentSongList.length > recentSongLimit) recentSongList.pop();
        updateRecentSongs();
    }

    function updateRecentSongs() {
        recentSongs.innerHTML = '';
        recentSongList.forEach(song => {
            const li = document.createElement('li');
            li.textContent = song;
            recentSongs.appendChild(li);
        });
    }

    // Play, pause, next, previous
    playButton.addEventListener('click', () => wavesurfer.play());
    pauseButton.addEventListener('click', () => wavesurfer.pause());
    prevButton.addEventListener('click', () => {
        currentSongIndex = (currentSongIndex - 1 + songs.length) % songs.length;
        loadSong(currentSongIndex);
        wavesurfer.play();
    });
    nextButton.addEventListener('click', () => {
        currentSongIndex = (currentSongIndex + 1) % songs.length;
        loadSong(currentSongIndex);
        wavesurfer.play();
    });

    // Progress bar and volume control
    wavesurfer.on('audioprocess', () => {
        progress.value = (wavesurfer.getCurrentTime() / wavesurfer.getDuration()) * 100;
    });

    progress.addEventListener('input', () => {
        wavesurfer.seekTo(progress.value / 100);
    });

    volume.addEventListener('input', () => {
        wavesurfer.setVolume(volume.value);
    });

    // Playback speed control
    speed.addEventListener('input', () => {
        wavesurfer.setPlaybackRate(speed.value);
    });

    // Load song on page load
    loadSong(currentSongIndex);

    // Handle audio uploads
    audioUpload.addEventListener('change', (event) => {
        const file = event.target.files[0];
        if (file) {
            const objectURL = URL.createObjectURL(file);
            songs.push({ title: file.name, src: objectURL });
            updatePlaylist();
        }
    });
});

