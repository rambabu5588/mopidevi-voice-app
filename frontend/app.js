document.addEventListener('DOMContentLoaded', () => {
    // State Variables
    let selectedStyle = 'Devotional';
    let currentJobId = null;
    let pollInterval = null;
    let mediaRecorder = null;
    let audioChunks = [];
    let recordedBlob = null;
    let audioCtx = null;
    let animFrame = null;

    // DOM Elements
    const tabBtns = document.querySelectorAll('.tab-btn');
    const tabContents = document.querySelectorAll('.tab-content');
    const scriptInput = document.getElementById('telugu-script-input');
    const charCountEl = document.getElementById('char-count');
    const btnClearScript = document.getElementById('btn-clear-script');
    const voiceSelect = document.getElementById('voice-select');
    const styleCards = document.querySelectorAll('.style-card');
    const quickTemplateBar = document.getElementById('quick-template-bar');
    const fxBell = document.getElementById('fx-bell');
    const fxAmbience = document.getElementById('fx-ambience');
    const fxConch = document.getElementById('fx-conch');
    const fxIntensity = document.getElementById('fx-intensity');
    const intensityVal = document.getElementById('intensity-val');
    const btnGenerate = document.getElementById('btn-generate');

    // Player & Progress Elements
    const progressBox = document.getElementById('pipeline-progress-box');
    const progressFill = document.getElementById('pipeline-progress-fill');
    const stepText = document.getElementById('pipeline-step-text');
    const playerContainer = document.getElementById('audio-player-container');
    const emptyPlayerState = document.getElementById('empty-player-state');
    const jobStatusBadge = document.getElementById('job-status-badge');
    const mainAudio = document.getElementById('main-audio-player');
    const btnPlayPause = document.getElementById('btn-play-pause');
    const playIcon = document.getElementById('play-icon');
    const currentTimeEl = document.getElementById('current-time');
    const totalDurationEl = document.getElementById('total-duration');
    const metaVoiceName = document.getElementById('meta-voice-name');
    const metaStyleName = document.getElementById('meta-style-name');
    const waveformCanvas = document.getElementById('waveform-canvas');

    // Action Buttons
    const btnDownloadMp3 = document.getElementById('btn-download-mp3');
    const btnOpenRegen = document.getElementById('btn-open-regen');
    const btnShare = document.getElementById('btn-share');

    // Recorder Elements
    const customVoiceNameInput = document.getElementById('custom-voice-name');
    const btnStartRecord = document.getElementById('btn-start-record');
    const btnStopRecord = document.getElementById('btn-stop-record');
    const btnUploadVoice = document.getElementById('btn-upload-voice');
    const recordedPreview = document.getElementById('recorded-preview');
    const qualityIndicator = document.getElementById('quality-indicator');
    const micBar = document.getElementById('mic-visualizer-bar');
    const voicesListContainer = document.getElementById('voices-list-container');
    const templatesGridContainer = document.getElementById('templates-grid-container');
    const historyListContainer = document.getElementById('history-list-container');

    // Modal Elements
    const modalRegen = document.getElementById('modal-regen');
    const btnCloseModal = document.getElementById('btn-close-modal');
    const btnCancelRegen = document.getElementById('btn-cancel-regen');
    const btnSubmitRegen = document.getElementById('btn-submit-regen');
    const modalStyleSelect = document.getElementById('modal-style-select');

    // 1. Tab Navigation
    tabBtns.forEach(btn => {
        btn.addEventListener('click', () => {
            tabBtns.forEach(b => b.classList.remove('active'));
            tabContents.forEach(c => c.classList.remove('active'));
            
            btn.classList.add('active');
            const target = btn.getAttribute('data-tab');
            document.getElementById(target).classList.add('active');

            if (target === 'tab-voices') loadVoicesList();
            if (target === 'tab-history') loadHistoryList();
            if (target === 'tab-training') loadTrainingRequests();
        });
    });

    // 2. Character Counter & Script Controls
    scriptInput.addEventListener('input', () => {
        const text = scriptInput.value;
        charCountEl.textContent = `${text.length} అక్షరాలు (${text.trim() ? text.trim().split(/\s+/).length : 0} పదాలు)`;
    });

    btnClearScript.addEventListener('click', () => {
        scriptInput.value = '';
        charCountEl.textContent = '0 అక్షరాలు';
    });

    // 3. Style Grid Selection
    styleCards.forEach(card => {
        card.addEventListener('click', () => {
            styleCards.forEach(c => c.classList.remove('active'));
            card.classList.add('active');
            selectedStyle = card.getAttribute('data-style');
        });
    });

// 4. Fetch Voices, Templates & User Assigned Voice
    const userRoleSelect = document.getElementById('user-role-select');
    const assignedVoiceBadge = document.getElementById('assigned-voice-badge');

    async function loadUserAssignedVoice(userId) {
        try {
            const res = await fetch(`/api/users/${userId}/assigned-voice`);
            const data = await res.json();
            if (data && assignedVoiceBadge) {
                assignedVoiceBadge.textContent = `${data.assigned_voice_id} (${data.assigned_version})`;
                if (voiceSelect) voiceSelect.value = data.assigned_voice_id;
            }
        } catch (e) {
            console.error('Failed to load user assigned voice:', e);
        }
    }

    if (userRoleSelect) {
        userRoleSelect.addEventListener('change', (e) => {
            loadUserAssignedVoice(e.target.value);
        });
    }

    async function loadVoices() {
        try {
            const res = await fetch('/api/voices');
            const voices = await res.json();
            voiceSelect.innerHTML = '';
            voices.forEach(v => {
                const opt = document.createElement('option');
                opt.value = v.id;
                opt.textContent = `${v.voice_name} (${v.quality_score})`;
                voiceSelect.appendChild(opt);
            });
            if (userRoleSelect) loadUserAssignedVoice(userRoleSelect.value);
        } catch (e) {
            console.error('Failed to load voices:', e);
        }
    }

    async function loadTemplates() {
        try {
            const res = await fetch('/api/templates');
            const templates = await res.json();
            
            // Build quick template bar
            quickTemplateBar.innerHTML = '<span class="pill-label">త్వరిత ఎంపికలు:</span>';
            templates.forEach(tpl => {
                const pill = document.createElement('button');
                pill.className = 'pill-btn';
                pill.textContent = tpl.title.split(' ')[0];
                pill.addEventListener('click', () => {
                    scriptInput.value = tpl.script;
                    scriptInput.dispatchEvent(new Event('input'));
                });
                quickTemplateBar.appendChild(pill);
            });

            // Build Templates Tab Grid
            templatesGridContainer.innerHTML = '';
            templates.forEach(tpl => {
                const card = document.createElement('div');
                card.className = 'template-card';
                card.innerHTML = `
                    <div>
                        <h4>${tpl.title}</h4>
                        <p>${tpl.script}</p>
                    </div>
                    <button class="btn btn-secondary btn-block">ఉపయోగించండి (Use Template)</button>
                `;
                card.querySelector('button').addEventListener('click', () => {
                    scriptInput.value = tpl.script;
                    scriptInput.dispatchEvent(new Event('input'));
                    document.querySelector('[data-tab="tab-create"]').click();
                });
                templatesGridContainer.appendChild(card);
            });

        } catch (e) {
            console.error('Failed to load templates:', e);
        }
    }

    // 5. Generate Announcement
    btnGenerate.addEventListener('click', async () => {
        const text = scriptInput.value.trim();
        if (!text) {
            alert('దయచేసి తెలుగు వ్యాఖ్యానం నమోదు చేయండి! (Please enter Telugu script)');
            return;
        }

        const voiceId = voiceSelect.value;
        const effectSettings = {
            bg_ambience: false,
            bell: false,
            conch: false,
            intensity: 0.0
        };

        // Reset UI
        emptyPlayerState.classList.add('hidden');
        playerContainer.classList.add('hidden');
        progressBox.classList.remove('hidden');
        jobStatusBadge.className = 'badge badge-neutral';
        jobStatusBadge.textContent = 'ప్రాసెసింగ్...';
        btnGenerate.disabled = true;

        try {
            const activeUserId = userRoleSelect ? userRoleSelect.value : 'user_default';
            const res = await fetch('/api/announcements/generate', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    user_id: activeUserId,
                    voice_id: voiceId,
                    telugu_script: text,
                    style: selectedStyle,
                    effect_settings: effectSettings
                })
            });

            const job = await res.json();
            currentJobId = job.id;
            startJobPolling(currentJobId);

        } catch (e) {
            console.error('Generation request failed:', e);
            alert('Error submitting job request');
            btnGenerate.disabled = false;
        }
    });

    // 6. Job Status Polling
    function startJobPolling(jobId) {
        if (pollInterval) clearInterval(pollInterval);
        
        pollInterval = setInterval(async () => {
            try {
                const res = await fetch(`/api/announcements/jobs/${jobId}`);
                const job = await res.json();
                
                stepText.textContent = job.current_step;
                progressFill.style.width = `${job.progress_percent}%`;

                // Update visual pipeline steps
                updatePipelineStepUI(job.progress_percent);

                if (job.status === 'COMPLETED') {
                    clearInterval(pollInterval);
                    btnGenerate.disabled = false;
                    jobStatusBadge.className = 'badge badge-success';
                    jobStatusBadge.textContent = 'పూర్తయింది (Ready)';
                    
                    progressBox.classList.add('hidden');
                    playerContainer.classList.remove('hidden');
                    
                    // Setup Player
                    mainAudio.src = job.output_mp3_path;
                    metaVoiceName.textContent = voiceSelect.options[voiceSelect.selectedIndex].text.split('(')[0];
                    metaStyleName.textContent = selectedStyle;
                    
                    btnDownloadMp3.onclick = () => {
                        const a = document.createElement('a');
                        a.href = job.output_mp3_path;
                        a.download = `Mopidevi_Announcement_${jobId}.mp3`;
                        a.click();
                    };

                } else if (job.status === 'FAILED') {
                    clearInterval(pollInterval);
                    btnGenerate.disabled = false;
                    alert(`ఆడియో ఉత్పత్తి విఫలమైంది: ${job.current_step}`);
                }

            } catch (e) {
                console.error('Polling error:', e);
            }
        }, 800);
    }

    function updatePipelineStepUI(percent) {
        const steps = [
            { id: 'step-1', threshold: 15 },
            { id: 'step-2', threshold: 30 },
            { id: 'step-3', threshold: 45 },
            { id: 'step-4', threshold: 75 },
            { id: 'step-5', threshold: 90 }
        ];

        steps.forEach(s => {
            const el = document.getElementById(s.id);
            if (percent >= s.threshold) {
                el.className = 'step-item completed';
                el.querySelector('span').textContent = '✓';
            } else if (percent >= s.threshold - 15) {
                el.className = 'step-item active';
                el.querySelector('span').textContent = '●';
            } else {
                el.className = 'step-item';
                el.querySelector('span').textContent = '○';
            }
        });
    }

    // 7. Audio Player Controls & Canvas Waveform
    btnPlayPause.addEventListener('click', () => {
        if (mainAudio.paused) {
            mainAudio.play();
            playIcon.textContent = '⏸';
            drawWaveformAnimation();
        } else {
            mainAudio.pause();
            playIcon.textContent = '▶';
            cancelAnimationFrame(animFrame);
        }
    });

    mainAudio.addEventListener('timeupdate', () => {
        const curr = formatTime(mainAudio.currentTime);
        const dur = formatTime(mainAudio.duration || 0);
        currentTimeEl.textContent = curr;
        totalDurationEl.textContent = dur;
    });

    mainAudio.addEventListener('ended', () => {
        playIcon.textContent = '▶';
        cancelAnimationFrame(animFrame);
        drawStaticWaveform();
    });

    function formatTime(secs) {
        const m = Math.floor(secs / 60);
        const s = Math.floor(secs % 60);
        return `${m}:${s < 10 ? '0' : ''}${s}`;
    }

    // Canvas Audio Waveform Rendering
    const ctx = waveformCanvas.getContext('2d');
    function drawStaticWaveform() {
        const w = waveformCanvas.width;
        const h = waveformCanvas.height;
        ctx.clearRect(0, 0, w, h);
        ctx.fillStyle = '#E5A93C';
        
        const bars = 40;
        const barW = w / bars - 4;
        for (let i = 0; i < bars; i++) {
            const barH = 15 + Math.sin(i * 0.4) * 20 + Math.random() * 10;
            ctx.fillRect(i * (barW + 4), (h - barH) / 2, barW, barH);
        }
    }
    drawStaticWaveform();

    function drawWaveformAnimation() {
        const w = waveformCanvas.width;
        const h = waveformCanvas.height;
        ctx.clearRect(0, 0, w, h);
        ctx.fillStyle = '#10B981';
        
        const time = Date.now() * 0.005;
        const bars = 40;
        const barW = w / bars - 4;
        for (let i = 0; i < bars; i++) {
            const barH = 20 + Math.abs(Math.sin(time + i * 0.3)) * 45;
            ctx.fillRect(i * (barW + 4), (h - barH) / 2, barW, barH);
        }
        
        if (!mainAudio.paused) {
            animFrame = requestAnimationFrame(drawWaveformAnimation);
        }
    }

    // 8. Voice Recorder Functionality
    btnStartRecord.addEventListener('click', async () => {
        try {
            const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
            audioChunks = [];
            mediaRecorder = new MediaRecorder(stream);
            
            mediaRecorder.ondataavailable = e => audioChunks.push(e.data);
            mediaRecorder.onstop = () => {
                recordedBlob = new Blob(audioChunks, { type: 'audio/wav' });
                recordedPreview.src = URL.createObjectURL(recordedBlob);
                recordedPreview.classList.remove('hidden');
                qualityIndicator.classList.remove('hidden');
                btnUploadVoice.disabled = false;
            };

            mediaRecorder.start();
            btnStartRecord.classList.add('hidden');
            btnStopRecord.classList.remove('hidden');

            // Simulate mic bar animation
            micBar.style.width = '60%';

        } catch (e) {
            alert('మైక్రోఫోన్ అనుమతి పొందడం లభ్యమవలేదు. (Microphone access denied)');
        }
    });

    btnStopRecord.addEventListener('click', () => {
        if (mediaRecorder && mediaRecorder.state !== 'inactive') {
            mediaRecorder.stop();
            btnStopRecord.classList.add('hidden');
            btnStartRecord.classList.remove('hidden');
            micBar.style.width = '0%';
        }
    });

    btnUploadVoice.addEventListener('click', async () => {
        const vName = customVoiceNameInput.value.trim();
        if (!vName || !recordedBlob) {
            alert('దయచేసి స్వర పేరును నమోదు చేయండి. (Please enter Voice Name)');
            return;
        }

        const formData = new FormData();
        formData.append('voice_name', vName);
        formData.append('file', recordedBlob, 'sample.wav');

        try {
            btnUploadVoice.disabled = true;
            btnUploadVoice.textContent = 'అప్‌లోడ్ చేస్తోంది...';
            const res = await fetch('/api/voices/upload', {
                method: 'POST',
                body: formData
            });
            await res.json();
            alert('స్వర ప్రొఫైల్ విజయవంతంగా సేవ్ చేయబడింది! (Voice Profile Saved Successfully)');
            customVoiceNameInput.value = '';
            recordedPreview.classList.add('hidden');
            qualityIndicator.classList.add('hidden');
            btnUploadVoice.textContent = '📤 స్వర ప్రొఫైల్ సేవ్ చేయి (Save Voice Profile)';
            loadVoices();
            loadVoicesList();
        } catch (e) {
            alert('Upload failed');
            btnUploadVoice.disabled = false;
        }
    });

    async function loadVoicesList() {
        try {
            const res = await fetch('/api/voices');
            const voices = await res.json();
            voicesListContainer.innerHTML = '';
            
            voices.forEach(v => {
                const item = document.createElement('div');
                item.className = 'history-item';
                item.innerHTML = `
                    <div>
                        <strong>${v.voice_name}</strong>
                        <div style="font-size:0.8rem; color:#94A3B8;">టైప్: ${v.voice_type === 'system' ? 'సిస్టమ్ స్వరము' : 'వ్యక్తిగత రికార్డింగ్'} | నాణ్యత: ${v.quality_score}</div>
                    </div>
                    <div>
                        ${v.voice_type === 'custom' ? `<button class="btn btn-danger btn-sm btn-delete-v" data-id="${v.id}">🗑️ తొలగించు (Delete)</button>` : '<span class="badge badge-neutral">డిఫాల్ట్</span>'}
                    </div>
                `;
                if (v.voice_type === 'custom') {
                    item.querySelector('.btn-delete-v').addEventListener('click', async () => {
                        if (confirm('మీరు ఈ స్వర ప్రొఫైల్‌ను మరియు రికార్డింగ్‌ను తొలగించాలనుకుంటున్నారా?')) {
                            await fetch(`/api/voices/${v.id}`, { method: 'DELETE' });
                            loadVoices();
                            loadVoicesList();
                        }
                    });
                }
                voicesListContainer.appendChild(item);
            });
        } catch (e) {
            console.error(e);
        }
    }

    async function loadHistoryList() {
        try {
            const res = await fetch('/api/announcements/history');
            const history = await res.json();
            historyListContainer.innerHTML = '';
            
            if (history.length === 0) {
                historyListContainer.innerHTML = '<p style="color:#94A3B8;">ఇంకా ఏ ఆడియో ప్రకటనలు ఉత్పత్తి చేయబడలేదు.</p>';
                return;
            }

            history.forEach(item => {
                const el = document.createElement('div');
                el.className = 'history-item';
                el.innerHTML = `
                    <div style="max-width: 70%;">
                        <strong style="color:#E5A93C;">${item.id} (${item.style})</strong>
                        <p style="font-size:0.85rem; margin-top:4px;">${item.telugu_script}</p>
                    </div>
                    <div>
                        ${item.output_mp3_path ? `<a href="${item.output_mp3_path}" target="_blank" class="btn btn-secondary btn-sm">▶ విను (Play)</a>` : '<span class="badge badge-neutral">విఫలమైంది</span>'}
                    </div>
                `;
                historyListContainer.appendChild(el);
            });

        } catch (e) {
            console.error(e);
        }
    }

    // 9. Regeneration Modal Handlers
    btnOpenRegen.addEventListener('click', () => {
        modalRegen.classList.remove('hidden');
    });

    btnCloseModal.addEventListener('click', () => modalRegen.classList.add('hidden'));
    btnCancelRegen.addEventListener('click', () => modalRegen.classList.add('hidden'));

    btnSubmitRegen.addEventListener('click', async () => {
        if (!currentJobId) return;
        const newStyle = modalStyleSelect.value;
        modalRegen.classList.add('hidden');

        // Trigger regeneration
        try {
            const res = await fetch(`/api/announcements/regenerate/${currentJobId}`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ style: newStyle })
            });

            const newJob = await res.json();
            currentJobId = newJob.id;
            
            playerContainer.classList.add('hidden');
            progressBox.classList.remove('hidden');
            startJobPolling(currentJobId);

        } catch (e) {
            alert('Regeneration failed');
        }
    });

    btnShare.addEventListener('click', () => {
        if (navigator.share && mainAudio.src) {
            navigator.share({
                title: 'మోపిదేవి ఆలయ ఆడియో ప్రకటన',
                text: 'మోపిదేవి ఆలయ ధ్వని అనువర్తనం ద్వారా ఉత్పత్తి చేసిన ఆడియో ప్రకటన',
                url: window.location.origin + mainAudio.src
            }).catch(() => {});
        } else {
            navigator.clipboard.writeText(window.location.origin + mainAudio.src);
            alert('ఆడియో లింక్ కాపీ చేయబడింది! (Audio link copied to clipboard)');
        }
    });

    // 10. Adaptive Voice Training Functionality
    async function loadTrainingRequests() {
        const container = document.getElementById('training-requests-container');
        if (!container) return;
        
        try {
            const res = await fetch('/api/voices/training-requests/user_default');
            const requests = await res.json();
            container.innerHTML = '';
            
            if (requests.length === 0) {
                container.innerHTML = `
                    <div class="empty-state">
                        <div class="empty-icon">✓</div>
                        <h3>శిక్షణ కోసం పెండింగ్ పదాలు లేవు</h3>
                        <p>మీ స్వర మోడల్ అన్ని ఆలయ పదాలకు సంపూర్ణంగా శిక్షణ పొందింది!</p>
                    </div>
                `;
                return;
            }

            requests.forEach(req => {
                const card = document.createElement('div');
                card.className = 'history-item';
                card.style.flexDirection = 'column';
                card.style.alignItems = 'flex-start';
                card.style.gap = '12px';
                card.innerHTML = `
                    <div style="width:100%; display:flex; justify-shadow:space-between; align-items:center;">
                        <strong style="color:#E5A93C; font-size:1.1rem;">లక్ష్య పదం: "${req.word_text}"</strong>
                        <span class="badge badge-neutral">PENDING TRAINING</span>
                    </div>
                    <p style="font-size:0.88rem; color:#94A3B8;">వాక్యం: ${req.sentence_text}</p>
                    <div style="width:100%; display:flex; gap:10px; align-items:center;">
                        <button class="btn btn-danger btn-sm btn-rec-snippet" data-id="${req.id}">🔴 ఈ పదాన్ని రికార్డ్ చేయి (Record Snippet)</button>
                        <button class="btn btn-secondary btn-sm btn-stop-snippet hidden" data-id="${req.id}">⏹️ ఆపివేయి</button>
                        <button class="btn btn-primary btn-sm btn-upload-snippet hidden" data-id="${req.id}">📤 మోడల్‌కు శిక్షణ ఇవ్వండి (Train Model)</button>
                    </div>
                `;
                
                let snippetRecorder = null;
                let snippetChunks = [];
                let snippetBlob = null;
                
                const recBtn = card.querySelector('.btn-rec-snippet');
                const stopBtn = card.querySelector('.btn-stop-snippet');
                const trainBtn = card.querySelector('.btn-upload-snippet');

                recBtn.addEventListener('click', async () => {
                    try {
                        const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
                        snippetChunks = [];
                        snippetRecorder = new MediaRecorder(stream);
                        snippetRecorder.ondataavailable = e => snippetChunks.push(e.data);
                        snippetRecorder.onstop = () => {
                            snippetBlob = new Blob(snippetChunks, { type: 'audio/wav' });
                            trainBtn.classList.remove('hidden');
                        };
                        snippetRecorder.start();
                        recBtn.classList.add('hidden');
                        stopBtn.classList.remove('hidden');
                    } catch (e) {
                        alert('మైక్రోఫోన్ అనుమతి లభ్యమవలేదు');
                    }
                });

                stopBtn.addEventListener('click', () => {
                    if (snippetRecorder && snippetRecorder.state !== 'inactive') {
                        snippetRecorder.stop();
                        stopBtn.classList.add('hidden');
                        recBtn.classList.remove('hidden');
                    }
                });

                trainBtn.addEventListener('click', async () => {
                    if (!snippetBlob) return;
                    const formData = new FormData();
                    formData.append('req_id', req.id);
                    formData.append('voice_id', req.voice_id);
                    formData.append('word_text', req.word_text);
                    formData.append('file', snippetBlob, `${req.word_text}.wav`);

                    try {
                        trainBtn.disabled = true;
                        trainBtn.textContent = 'శిక్షణ నిస్తోంది...';
                        const res = await fetch('/api/voices/train-sample', {
                            method: 'POST',
                            body: formData
                        });
                        await res.json();
                        alert(`"${req.word_text}" పదం కోసం మీ స్వర మోడల్ విజయవంతంగా శిక్షణ పొందింది!`);
                        loadTrainingRequests();
                    } catch (e) {
                        alert('Training upload failed');
                        trainBtn.disabled = false;
                    }
                });

                container.appendChild(card);
            });

        } catch (e) {
            console.error('Failed to load training requests:', e);
        }
    }

    // 11. Mobile Voice Training Session Handler
    const trainingSentences = [
        "శ్రీ మోపిదేవి సుబ్రహ్మణ్యేశ్వర స్వామి వారి పవిత్ర దివ్య క్షేత్రానికి విచ్చేసిన భక్తులందరికీ హృదయపూర్వక స్వాగతం.",
        "ఉదయం 10:30 AM గంటలకు సర్పదోష నివారణ పూజ మరియు అభిషేకం ప్రారంభమగును.",
        "భక్తులు అందరూ వరుసక్రమంలో ప్రశాంతంగా వెళ్ళి నాగేంద్రస్వామి వారి దివ్య దర్శనం చేసుకోవాల్సిందిగా మనవి.",
        "స్వామివారి పవిత్ర తీర్థప్రసాదములు ఆలయ ప్రాంగణము వెనుక భాగాన వితరణ చేయబడుచున్నవి.",
        "శ్రీ వల్లీ దేవసేన సమేత శ్రీ సుబ్రహ్మణ్య స్వామి వారి దివ్య మంగళ స్వరూపం మన అందరికీ మంగళం చేకూర్చుగాక."
    ];
    let currentSentenceIdx = 0;
    let sessionRecorder = null;
    let sessionChunks = [];

    const btnTrainRec = document.getElementById('btn-train-rec');
    const btnTrainStop = document.getElementById('btn-train-stop');
    const btnTrainRetake = document.getElementById('btn-train-retake');
    const btnTrainAccept = document.getElementById('btn-train-accept');
    const trainPreviewAudio = document.getElementById('train-preview-audio');
    const trainQualityBadges = document.getElementById('train-quality-badges');
    const targetSentenceText = document.getElementById('target-sentence-text');
    const trainingSessionBadge = document.getElementById('training-session-badge');

    function updateTrainingSentenceDisplay() {
        if (targetSentenceText) targetSentenceText.textContent = `"${trainingSentences[currentSentenceIdx]}"`;
        if (trainingSessionBadge) trainingSessionBadge.textContent = `సెషన్ ${currentSentenceIdx + 1} / ${trainingSentences.length}`;
        if (trainPreviewAudio) {
            trainPreviewAudio.classList.add('hidden');
            trainPreviewAudio.src = '';
        }
        if (trainQualityBadges) trainQualityBadges.classList.add('hidden');
        if (btnTrainRetake) btnTrainRetake.classList.add('hidden');
        if (btnTrainAccept) btnTrainAccept.classList.add('hidden');
        if (btnTrainRec) btnTrainRec.classList.remove('hidden');
    }

    if (btnTrainRec) {
        btnTrainRec.addEventListener('click', async () => {
            try {
                const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
                sessionChunks = [];
                sessionRecorder = new MediaRecorder(stream);
                sessionRecorder.ondataavailable = e => sessionChunks.push(e.data);
                sessionRecorder.onstop = () => {
                    const blob = new Blob(sessionChunks, { type: 'audio/wav' });
                    trainPreviewAudio.src = URL.createObjectURL(blob);
                    trainPreviewAudio.classList.remove('hidden');
                    trainQualityBadges.classList.remove('hidden');
                    btnTrainRetake.classList.remove('hidden');
                    btnTrainAccept.classList.remove('hidden');
                };
                sessionRecorder.start();
                btnTrainRec.classList.add('hidden');
                btnTrainStop.classList.remove('hidden');
            } catch (e) {
                alert('మైక్రోఫోన్ అనుమతి లభ్యమవలేదు');
            }
        });

        btnTrainStop.addEventListener('click', () => {
            if (sessionRecorder && sessionRecorder.state !== 'inactive') {
                sessionRecorder.stop();
                btnTrainStop.classList.add('hidden');
            }
        });

        btnTrainRetake.addEventListener('click', () => {
            updateTrainingSentenceDisplay();
        });

        btnTrainAccept.addEventListener('click', () => {
            currentSentenceIdx = (currentSentenceIdx + 1) % trainingSentences.length;
            alert(`వాక్యం ${currentSentenceIdx === 0 ? trainingSentences.length : currentSentenceIdx} విజయవంతంగా ఆమోదించబడింది!`);
            updateTrainingSentenceDisplay();
        });
    }

    // Initial Load
    loadVoices();
    loadTemplates();
});
