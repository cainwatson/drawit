import React, { PureComponent } from 'react';
import styled from 'react-emotion';
import ReactRouterPropTypes from 'react-router-prop-types';
import Button from '../Util/Button';
import Input from '../Util/Input';

const Container = styled('div')`
  display: flex;
  flex-direction: column;
  text-align: center;
`;

class JoinGame extends PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      joinCode: '',
      error: '',
    };

    this.setJoinCode = this.setJoinCode.bind(this);
    this.join = this.join.bind(this);
  }

  setJoinCode({ target }) {
    this.setState({ joinCode: target.value });
  }

  join() {
    const { joinCode } = this.state;
    if (joinCode.length >= 7) {
      this.props.history.push(`/games/${this.state.joinCode}`);
    } else {
      this.setState({ error: 'Join code must be at least 7 chars long.' });
    }
  }

  render() {
    return (
      <Container>
        <Input onChange={this.setJoinCode} placeholder="Join code" type="text" />
        <Button onClick={this.join}>Play!</Button>
        <span>or</span>
        {this.state.error ? <p>{this.state.error}</p> : null}
      </Container>
    );
  }
}

JoinGame.propTypes = {
  history: ReactRouterPropTypes.history.isRequired,
};

export default JoinGame;