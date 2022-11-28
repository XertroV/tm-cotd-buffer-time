interface CPAbstraction {
    const array<int>@ get_cpTimes() const;
    // time lost to respawns
    const array<int>@ get_tltr() const;
    int get_cpCount() const;
    int get_lastCpTime() const;
    int get_lastCpTimeRaw() const;
    int opCmp(const CPAbstraction@ other) const;
    string ToString() const;
}

mixin class CPAbstractionOpCmp : CPAbstraction {
    int opCmp(const CPAbstraction@ other) const {
        if (other is null) return -1;
        if (this.cpCount > other.cpCount) return -1;
        if (this.cpCount < other.cpCount) return 1;
        if (this.lastCpTime > other.lastCpTime) return 1;
        if (this.lastCpTime < other.lastCpTime) return -1;
        return 0;
    }

    string ToString() const {
        return "CP(count=" + this.cpCount + ", last=" + this.lastCpTime + ")";
    }
}

class WrapPlayerCpInfo : CPAbstraction, CPAbstractionOpCmp {
    const MLFeed::PlayerCpInfo_V2@ _inner;
    WrapPlayerCpInfo(const MLFeed::PlayerCpInfo_V2@ cpInfo) {
        @_inner = cpInfo;
    }
    const array<int>@ get_cpTimes() const {
        return _inner.cpTimes;
    }
    const array<int>@ get_tltr() const {
        return _inner.TimeLostToRespawnByCp;
    }
    int get_cpCount() const {
        return _inner.cpCount;
    }
    int get_lastCpTime() const {
        return S_UpdateInstantRespawns ? _inner.LastCpOrRespawnTime : _inner.LastCpTime;
    }
    int get_lastCpTimeRaw() const {
        return _inner.LastCpTime;
    }


    void UpdateFrom(const MLFeed::PlayerCpInfo_V2@ cpInfo) {
        @_inner = cpInfo;
    }
}

const uint[] EmptyUintArray;

class WrappedTimes : CPAbstraction, CPAbstractionOpCmp {
    protected int _cpCount;
    protected int _lastCpTime;
    protected array<int> _cpTimes;
    int currRaceTime;
    int innerResultTime = -1;
    string ghostName;
    const array<uint>@ rawCheckpoints = EmptyUintArray;
    array<int> _tltr = array<int>(1);

    const array<int>@ get_cpTimes() const {
        return _cpTimes;
    }
    const array<int>@ get_tltr() const {
        return _tltr;
    }
    int get_cpCount() const {
        return _cpCount;
    }
    int get_lastCpTime() const {
        return _lastCpTime;
    }
    int get_lastCpTimeRaw() const {
        return _lastCpTime;
    }

    bool get_IsEmpty() const {
        return innerResultTime <= 0;
    }

    // hmm, this does not seem to work for `priorityGhost == secondaryGhost`, so is it using opCmp from above?
    bool opEquals(const WrappedTimes@ other) {
        auto l = this.rawCheckpoints.Length;
        return other !is null
            && this.innerResultTime == other.innerResultTime
            && other.cpCount == this.cpCount
            && other.lastCpTime == this.lastCpTime
            // && other.rawCheckpoints.Length == this.rawCheckpoints.Length
            // && (l == 0 || other.rawCheckpoints[l - 1] == this.rawCheckpoints[l - 1])
            ;
    }
}

class WrapBestTimes : WrappedTimes {
    private array<int> _inner;

    WrapBestTimes(const string &in playerName, const array<uint>@ cpInfo, int crt, int minCPs) {
        currRaceTime = crt;
        ghostName = playerName;
        @rawCheckpoints = cpInfo;
        _inner.Resize(cpInfo.Length + 1);
        _inner[0] = 0;
        _cpCount = 0;
        _lastCpTime = 0;
        if (cpInfo.Length > 0)
            innerResultTime = cpInfo[cpInfo.Length - 1];
        for (uint i = 0; i < cpInfo.Length; i++) {
            _inner[i+1] = cpInfo[i];
            if (int(cpInfo[i]) <= crt || (S_TA_UpdateTimerImmediately && int(i) < minCPs)) {
                _cpCount++;
                _lastCpTime = cpInfo[i];
            }
        }
        _cpTimes.Resize(_cpCount + 1);
        for (uint i = 0; i < _cpTimes.Length; i++) {
            _cpTimes[i] = _inner[i];
        }
        _tltr.Resize(rawCheckpoints.Length + 2);
    }

    void UpdateFrom(const string &in playerName, const array<uint>@ cpInfo, int crt, int minCPs) {
        currRaceTime = crt;
        if (ghostName == playerName && _inner.Length == cpInfo.Length + 1 && _inner[cpInfo.Length] == int(cpInfo[cpInfo.Length - 1])) {
            // don't need to update but might be a PITA to have extra logic to recalc cpCount etc based on CRT
        } else {
            ghostName = playerName;
            _inner.Resize(cpInfo.Length + 1);
            _inner[0] = 0;
            @rawCheckpoints = cpInfo;
        }
        _cpCount = 0;
        _lastCpTime = 0;
        if (cpInfo.Length > 0)
            innerResultTime = cpInfo[cpInfo.Length - 1];
        for (uint i = 0; i < cpInfo.Length; i++) {
            _inner[i+1] = cpInfo[i];
            if (int(cpInfo[i]) <= crt || (S_TA_UpdateTimerImmediately && int(i) < minCPs)) {
                _cpCount++;
                _lastCpTime = cpInfo[i];
            }
        }
        _cpTimes.Resize(_cpCount + 1);
        for (uint i = 0; i < _cpTimes.Length; i++) {
            _cpTimes[i] = _inner[i];
        }
    }

    void UpdateFromCRT(int crt, int minCPs) {
        currRaceTime = crt;
        _cpCount = 0;
        _lastCpTime = 0;
        for (uint i = 0; i < rawCheckpoints.Length; i++) {
            if (int(rawCheckpoints[i]) <= crt || (S_TA_UpdateTimerImmediately && int(i) < minCPs)) {
                _cpCount++;
                _lastCpTime = rawCheckpoints[i];
            }
        }
        _cpTimes.Resize(_cpCount + 1);
        for (uint i = 0; i < _cpTimes.Length; i++) {
            _cpTimes[i] = _inner[i];
        }
    }
}

class WrapGhostInfo : WrappedTimes {
    private const MLFeed::GhostInfo@ _inner;

    WrapGhostInfo(const MLFeed::GhostInfo@ ghostInfo, int crt, int minCPs) {
        currRaceTime = crt;
        _cpTimes.InsertLast(0);
        if (ghostInfo is null) return;
        @_inner = ghostInfo;
        innerResultTime = ghostInfo.Result_Time;
        @rawCheckpoints = ghostInfo.Checkpoints;
        if (ghostInfo.Nickname.EndsWith("Personal best"))
            ghostName = "Personal best";
        else
            ghostName = ghostInfo.Nickname;

        for (uint i = 0; i < rawCheckpoints.Length; i++) {
            if (int(rawCheckpoints[i]) <= crt || (S_TA_UpdateTimerImmediately && int(i) < minCPs)) _cpCount++;
            else break;
            _cpTimes.InsertLast(rawCheckpoints[i]);
        }
        if (_cpCount > 0) _lastCpTime = rawCheckpoints[_cpCount - 1];
        _tltr.Resize(rawCheckpoints.Length + 2);
    }

    void UpdateFrom(const MLFeed::GhostInfo@ ghostInfo, int crt, int minCPs) {
        if (ghostInfo !is null) {
            if (innerResultTime != ghostInfo.Result_Time) {
                @_inner = ghostInfo;
                @rawCheckpoints = ghostInfo.Checkpoints;
                innerResultTime = ghostInfo.Result_Time;
                if (ghostInfo.Nickname.EndsWith("Personal best"))
                    ghostName = "Personal best";
                else
                    ghostName = ghostInfo.Nickname;
            }
        }
        currRaceTime = crt;
        if (_cpTimes.Length == 0) _cpTimes.InsertLast(0);
        // shouldn't need to set to 0, but its cheap
        // else _cpTimes[0] = 0;
        _cpCount = 0;
        for (uint i = 0; i < rawCheckpoints.Length; i++) {
            if (int(rawCheckpoints[i]) <= crt || (S_TA_UpdateTimerImmediately && int(i) < minCPs)) _cpCount++;
            else break;
        }
        if (int(_cpTimes.Length) != _cpCount + 1) {
            _cpTimes.Resize(_cpCount + 1);
        }
        for (int i = 0; i < _cpCount; i++) {
            _cpTimes[i+1] = rawCheckpoints[i];
        }
        _lastCpTime = _cpCount > 0 ? rawCheckpoints[_cpCount - 1] : 0;
    }
}
