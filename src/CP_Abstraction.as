interface CPAbstraction {
    const array<int>@ get_cpTimes() const;
    int get_cpCount() const;
    int get_lastCpTime() const;
    int opCmp(const CPAbstraction@ other) const;
    string ToString() const;
}

mixin class CPAbstractionOpCmp : CPAbstraction {
    int opCmp(const CPAbstraction@ other) const {
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
    const MLFeed::PlayerCpInfo@ _inner;
    WrapPlayerCpInfo(const MLFeed::PlayerCpInfo@ cpInfo) {
        @_inner = cpInfo;
    }
    const array<int>@ get_cpTimes() const {
        return _inner.cpTimes;
    }
    int get_cpCount() const {
        return _inner.cpCount;
    }
    int get_lastCpTime() const {
        return _inner.lastCpTime;
    }

    void UpdateFrom(const MLFeed::PlayerCpInfo@ cpInfo) {
        @_inner = cpInfo;
    }
}

class WrappedTimes : CPAbstraction, CPAbstractionOpCmp {
    protected int _cpCount;
    protected int _lastCpTime;
    protected array<int> _cpTimes;
    int currRaceTime;
    int innerResultTime = -1;
    string ghostName;

    const array<int>@ get_cpTimes() const {
        return _cpTimes;
    }
    int get_cpCount() const {
        return _cpCount;
    }
    int get_lastCpTime() const {
        return _lastCpTime;
    }

    bool get_IsEmpty() const {
        return innerResultTime <= 0;
    }
}

class WrapBestTimes : WrappedTimes {
    private array<int> _inner;

    WrapBestTimes(const string &in playerName, const array<uint>@ cpInfo, int crt) {
        currRaceTime = crt;
        ghostName = playerName;
        _inner.Resize(cpInfo.Length + 1);
        _inner[0] = 0;
        _cpCount = 0;
        _lastCpTime = 0;
        if (cpInfo.Length > 0)
            innerResultTime = cpInfo[cpInfo.Length - 1];
        for (uint i = 0; i < cpInfo.Length; i++) {
            _inner[i+1] = cpInfo[i];
            if (int(cpInfo[i]) < crt) {
                _cpCount++;
                _lastCpTime = cpInfo[i];
            }
        }
        _cpTimes.Resize(_cpCount + 1);
        for (uint i = 0; i < _cpTimes.Length; i++) {
            _cpTimes[i] = _inner[i];
        }
    }

    void UpdateFrom(const string &in playerName, const array<uint>@ cpInfo, int crt) {
        currRaceTime = crt;
        // if (ghostName == playerName && _inner.Length == cpInfo.Length + 1 && _inner[cpInfo.Length] == cpInfo[cpInfo.Length - 1]) {
        //     // don't need to update but might be a PITA to have extra logic to recalc cpCount etc based on CRT
        // }
        ghostName = playerName;
        _inner.Resize(cpInfo.Length + 1);
        _inner[0] = 0;
        _cpCount = 0;
        _lastCpTime = 0;
        if (cpInfo.Length > 0)
            innerResultTime = cpInfo[cpInfo.Length - 1];
        for (uint i = 0; i < cpInfo.Length; i++) {
            _inner[i+1] = cpInfo[i];
            if (int(cpInfo[i]) < crt) {
                _cpCount++;
                _lastCpTime = cpInfo[i];
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
    array<uint> giCheckpoints;
    WrapGhostInfo(const MLFeed::GhostInfo@ ghostInfo, int crt) {
        currRaceTime = crt;
        _cpTimes.InsertLast(0);
        if (ghostInfo is null) return;
        @_inner = ghostInfo;
        innerResultTime = ghostInfo.Result_Time;
        giCheckpoints = ghostInfo.Checkpoints;
        ghostName = ghostInfo.Nickname;

        for (uint i = 0; i < giCheckpoints.Length; i++) {
            if (crt > int(giCheckpoints[i])) _cpCount++;
            else break;
            _cpTimes.InsertLast(giCheckpoints[i]);
        }
        if (_cpCount > 0) _lastCpTime = giCheckpoints[_cpCount - 1];
    }

    bool opEquals(const WrapGhostInfo@ other) {
        return other !is null
            && other.cpCount == this.cpCount
            && other.lastCpTime == this.lastCpTime
            && innerResultTime == other.innerResultTime;
    }

    void UpdateFrom(const MLFeed::GhostInfo@ ghostInfo, int crt) {
        if (ghostInfo !is null) {
            if (innerResultTime != ghostInfo.Result_Time) {
                @_inner = ghostInfo;
                giCheckpoints = ghostInfo.Checkpoints;
                innerResultTime = ghostInfo.Result_Time;
                ghostName = ghostInfo.Nickname;
            }
        }
        currRaceTime = crt;
        if (_cpTimes.Length == 0) _cpTimes.InsertLast(0);
        // shouldn't need to set to 0, but its cheap
        // else _cpTimes[0] = 0;
        _cpCount = 0;
        for (uint i = 0; i < giCheckpoints.Length; i++) {
            if (crt > int(giCheckpoints[i])) _cpCount++;
            else break;
        }
        if (int(_cpTimes.Length) != _cpCount + 1) {
            _cpTimes.Resize(_cpCount + 1);
        }
        for (int i = 0; i < _cpCount; i++) {
            _cpTimes[i+1] = giCheckpoints[i];
        }
        _lastCpTime = _cpCount > 0 ? giCheckpoints[_cpCount - 1] : 0;
    }
}
