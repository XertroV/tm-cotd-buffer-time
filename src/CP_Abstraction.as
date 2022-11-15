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

class WrapGhostInfo : CPAbstraction, CPAbstractionOpCmp {
    const MLFeed::GhostInfo@ _inner;
    int currRaceTime;
    int _cpCount = 0;
    int _lastCpTime = 0;
    array<int> _cpTimes;
    WrapGhostInfo(const MLFeed::GhostInfo@ ghostInfo, int crt) {
        currRaceTime = crt;
        _cpTimes.InsertLast(0);
        if (ghostInfo is null) return;
        @_inner = ghostInfo;
        for (uint i = 0; i < ghostInfo.Checkpoints.Length; i++) {
            if (crt > ghostInfo.Checkpoints[i]) _cpCount++;
            else break;
            _cpTimes.InsertLast(ghostInfo.Checkpoints[i]);
        }
        if (_cpCount > 0) _lastCpTime = ghostInfo.Checkpoints[_cpCount - 1];
    }
    const array<int>@ get_cpTimes() const {
        return _cpTimes;
    }
    int get_cpCount() const {
        return _cpCount;
    }
    int get_lastCpTime() const {
        return _lastCpTime;
    }

    void UpdateFrom(const MLFeed::GhostInfo@ ghostInfo, int crt) {
        @_inner = ghostInfo;
        currRaceTime = crt;
        if (_cpTimes.Length == 0) _cpTimes.InsertLast(0);
        // shouldn't need to set to 0, but its cheap
        else _cpTimes[0] = 0;
        _cpCount = 0;
        for (uint i = 0; i < ghostInfo.Checkpoints.Length; i++) {
            if (crt > ghostInfo.Checkpoints[i]) _cpCount++;
            else break;
        }
        if (_cpTimes.Length != _cpCount + 1) {
            _cpTimes.Resize(_cpCount + 1);
        }
        for (uint i = 0; i < _cpCount; i++) {
            _cpTimes[i+1] = ghostInfo.Checkpoints[i];
        }
        _lastCpTime = _cpCount > 0 ? ghostInfo.Checkpoints[_cpCount - 1] : 0;
    }
}
